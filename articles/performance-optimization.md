# Performance Optimization Guide

## pladdrr Performance Optimization Guide

This guide explains the **3-tier performance API** in pladdrr and how to
choose the right level for your needs.

### The Three Performance Tiers

pladdrr provides three API tiers, each trading interface simplicity for
lower per-call overhead:

    ┌─────────────────────────────────────────────────────────┐
    │ TIER 1: High-Level API (Sound, Pitch, Formant, etc.)   │
    │ - Full object-oriented interface                        │
    │ - Method chaining: sound$to_pitch()$get_mean()         │
    │ - Best for: Interactive analysis, small datasets        │
    └─────────────────────────────────────────────────────────┘
               ↓
    ┌─────────────────────────────────────────────────────────┐
    │ TIER 2: Direct API (*_direct functions)                 │
    │ - Accept XPtr directly, skip object dispatch            │
    │ - Best for: Tight loops, repeated queries                │
    │ - Reduces per-call R dispatch overhead                  │
    └─────────────────────────────────────────────────────────┘
               ↓
    ┌─────────────────────────────────────────────────────────┐
    │ TIER 3: Batch/Parallel API (*_batch, *_parallel)        │
    │ - Designed for bulk operations                          │
    │ - Best for: Large datasets, production workflows        │
    │ - Replaces many R->C crossings with one per call        │
    └─────────────────────────────────────────────────────────┘

------------------------------------------------------------------------

### When do the tiers actually matter?

It depends entirely on how much work each call does relative to the
R-to-C++ boundary it crosses.

- **Querying in a tight loop** — thousands of cheap point queries — is
  where the batch and direct APIs are worth reaching for, because the
  per-call dispatch overhead is a larger share of the total cost. Going
  from one crossing per query to one crossing per vector changes the
  shape of that cost.
- **A single analysis call** — `to_pitch()`, `to_formant_burg()`,
  [`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md)
  — is dominated by the underlying DSP work, and the tier you call it
  through makes little practical difference. The different CPPS entry
  points (`sound$to_powercepstrogram()$get_cpps()`,
  [`calculate_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_fast.md),
  [`calculate_cpps_ultra()`](https://humlab-speech.github.io/pladdrr/reference/calculate_cpps_ultra.md))
  all compute the same value using the same core algorithm.

Rule of thumb: reach for a batch or direct function when you are about
to write a loop over query points or files. Switching analysis entry
points for a single call is not expected to help — measure your own
workload with [`system.time()`](https://rdrr.io/r/base/system.time.html)
if you’re unsure.

------------------------------------------------------------------------

### Tier 1: High-Level API (Best for Most Users)

**When to use:** Interactive analysis, exploration, small datasets
(\<100 files)

**Characteristics:** - Intuitive object-oriented interface - Method
chaining - Full error checking and validation - Easy to read and
maintain

``` r

library(pladdrr)
#> pladdrr: direct access to Praat's core algorithms from R.
#> See ?pladdrr for an overview, or citation("pladdrr") for citation details.

wav_file <- system.file("extdata", "test.wav", package = "pladdrr")

# Load sound
sound <- Sound(wav_file)

# Extract pitch (returns Pitch object)
pitch <- sound$to_pitch(pitch_floor = 75, pitch_ceiling = 300)

# Query statistics
mean_f0 <- pitch$get_mean(0, 0, "hertz")
sd_f0 <- pitch$get_standard_deviation(0, 0, "hertz")

# Method chaining
mean_f1 <- sound$to_formant()$get_mean(1, 0, 0, "hertz")
```

Adequate for most use cases. Only reach for Tier 2/3 if profiling your
own code shows a bottleneck.

------------------------------------------------------------------------

### Tier 2: Direct API

**When to use:** Processing \>100 files, tight loops, production code

**Characteristics:** - Functions accept external pointers (XPtr)
directly - Skip R6 object dispatch overhead - Return raw values or
pointers - Require manual pointer extraction

``` r

# Extract pointer once
sound_ptr <- sound$.xptr

# Direct conversion (returns XPtr, not Pitch object)
pitch_ptr <- to_pitch_direct(sound_ptr,
                              time_step = 0,
                              pitch_floor = 75,
                              pitch_ceiling = 300)

# Get statistics in one call
stats <- get_pitch_stats_direct(pitch_ptr)
# Returns: list(min, max, mean, stdev, median, q25, q75, count_voiced)

# Get F1-F4 in one call
formant_ptr <- to_formant_direct(sound_ptr)
formants <- get_formants_direct(formant_ptr, time = 0.5)
# Returns: c(F1 = 500, F2 = 1500, F3 = 2500, F4 = 3500)
```

#### Fewer R→C boundary crossings

``` r

# Tier 1 approach: one boundary crossing per query
min_f0 <- pitch$get_minimum(0, 0, "hertz")
max_f0 <- pitch$get_maximum(0, 0, "hertz")
mean_f0 <- pitch$get_mean(0, 0, "hertz")
# ... 5 more calls

# Tier 2 approach: one boundary crossing for all statistics
stats <- get_pitch_stats_direct(pitch)
```

#### Available Direct Functions

**Conversion:** -
[`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md) -
Create Pitch -
[`to_formant_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_formant_direct.md) -
Create Formant -
[`to_intensity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_intensity_direct.md) -
Create Intensity -
[`to_harmonicity_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_harmonicity_direct.md) -
Create Harmonicity -
[`to_spectrum_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrum_direct.md) -
Create Spectrum -
[`to_spectrogram_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_spectrogram_direct.md) -
Create Spectrogram -
[`to_ltas_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_ltas_direct.md) -
Create LTAS -
[`to_point_process_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md) -
Create PointProcess

**Queries:** -
[`get_pitch_stats_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stats_direct.md) -
All pitch statistics at once -
[`get_formants_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_direct.md) -
F1-F4 at time point -
[`get_pitch_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_value_direct.md) -
Single pitch value -
[`get_intensity_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_value_direct.md) -
Single intensity value -
[`get_formant_value_direct()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_value_direct.md) -
Single formant value

------------------------------------------------------------------------

### Tier 3: Batch & Parallel API

**When to use:** Large datasets (\>100 files), production pipelines

#### Batch Operations

Process multiple sounds in a single C++ call:

``` r

# In practice `files` would be a vector of paths to distinct recordings, e.g.
# list.files("audio/", pattern = "\\.wav$", full.names = TRUE). This example
# repeats the bundled test file to keep the vignette self-contained.
files <- rep(wav_file, 3)

# Load multiple sounds
sounds <- lapply(files, Sound)

# Tier 1 approach: one R->C crossing per sound
pitches <- lapply(sounds, function(s) s$to_pitch())

# Tier 3 approach: one R->C crossing for the whole list
pitches <- sound_to_pitch_batch(sounds)
```

**Available batch functions:** -
[`sound_to_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_batch.md) -
Batch pitch extraction -
[`sound_to_pitch_ac_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_ac_batch.md) -
Batch autocorrelation pitch -
[`sound_to_pitch_cc_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_cc_batch.md) -
Batch cross-correlation pitch -
[`sound_to_formant_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_formant_batch.md) -
Batch formant extraction -
[`sound_to_intensity_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_intensity_batch.md) -
Batch intensity extraction

#### Vectorized Queries

Extract values at multiple time points in one call:

``` r

# Tier 1 approach: one R->C crossing per time point
times <- seq(0.1, 1.0, by = 0.01)
f0_values <- sapply(times, function(t) {
  pitch$get_value_at_time(t, "hertz")
})

# Tier 3 approach: one R->C crossing for the whole vector
f0_values <- get_pitch_at_times(pitch, times)
```

**Vectorized query functions:** -
[`get_pitch_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_at_times.md) -
Batch pitch queries -
[`get_formants_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_formants_at_times.md) -
Batch F1-F4 queries -
[`get_intensity_at_times()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_times.md) -
Batch intensity queries

#### Parallel Processing

Distribute file-level work across multiple CPU cores:

``` r

# Analyze files in parallel. In practice `files` is a vector of paths to
# distinct recordings, e.g. list.files("audio/", pattern = "\\.wav$",
# full.names = TRUE); this example repeats the bundled test file.
files <- rep(wav_file, 4)

# Simple parallel analysis
results <- analyze_files_parallel(files, function(sound) {
  pitch <- sound$to_pitch()
  list(
    mean_f0 = pitch$get_mean(0, 0, "hertz"),
    sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
  )
}, n_cores = 2)
#> Processing 4 files using 2 cores (2 thread(s)/worker)

# Convenience functions
pitches <- extract_pitch_parallel(files, n_cores = 2)
#> Processing 4 files using 2 cores (2 thread(s)/worker)
formants <- extract_formant_parallel(files, n_cores = 2)
#> Processing 4 files using 2 cores (2 thread(s)/worker)
intensities <- extract_intensity_parallel(files, n_cores = 2)
#> Processing 4 files using 2 cores (2 thread(s)/worker)
```

**Parallel functions:** -
[`analyze_files_parallel()`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md) -
Generic parallel file processing -
[`process_sounds_parallel()`](https://humlab-speech.github.io/pladdrr/reference/process_sounds_parallel.md) -
Parallel processing of loaded sounds -
[`extract_pitch_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch_parallel.md) -
Parallel pitch extraction -
[`extract_formant_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_formant_parallel.md) -
Parallel formant extraction -
[`extract_intensity_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_intensity_parallel.md) -
Parallel intensity extraction -
[`benchmark_parallel()`](https://humlab-speech.github.io/pladdrr/reference/benchmark_parallel.md) -
Measure your own workload across core counts

------------------------------------------------------------------------

### Tier Comparison Examples

The examples below use
[`system.time()`](https://rdrr.io/r/base/system.time.html) so you can
measure each approach against your own files and hardware — the numbers
vary too much by machine, file size, and workload to be worth quoting
here.

#### Example 1: Single File Analysis

``` r

sound <- Sound(wav_file)

# Tier 1: Standard API
system.time({
  pitch <- sound$to_pitch()
  mean_f0 <- pitch$get_mean(0, 0, "hertz")
  sd_f0 <- pitch$get_standard_deviation(0, 0, "hertz")
  min_f0 <- pitch$get_minimum(0, 0, "hertz")
  max_f0 <- pitch$get_maximum(0, 0, "hertz")
})
#>    user  system elapsed 
#>   0.011   0.001   0.006
# measure on your own data

# Tier 2: Direct API
system.time({
  pitch_ptr <- to_pitch_direct(sound$.xptr)
  stats <- get_pitch_stats_direct(pitch_ptr)
})
#>    user  system elapsed 
#>   0.011   0.000   0.005
# fewer crossings; measure on your own data
```

#### Example 2: Batch Processing

``` r

# In practice `files` is a vector of paths to distinct recordings, e.g.
# list.files("audio/", full.names = TRUE)[1:100]; this example repeats the
# bundled test file to keep the vignette self-contained and fast to build.
files <- rep(wav_file, 20)

# Tier 1: Sequential
system.time({
  sounds <- lapply(files, Sound)
  pitches <- lapply(sounds, function(s) s$to_pitch())
})
#>    user  system elapsed 
#>   0.212   0.011   0.105
# measure on your own data

# Tier 3: Batch
system.time({
  sounds <- lapply(files, Sound)
  pitches <- sound_to_pitch_batch(sounds)
})
#>    user  system elapsed 
#>   0.207   0.009   0.098
# scales with cores; measure on your own data

# Tier 3: Parallel (2 cores)
system.time({
  pitches <- extract_pitch_parallel(files, n_cores = 2)
})
#> Processing 20 files using 2 cores (2 thread(s)/worker)
#>    user  system elapsed 
#>   0.098   0.098   0.391
# includes file I/O; measure on your own data
```

#### Example 3: Formant Tracking Over Time

``` r

sound <- Sound(wav_file)
formant <- sound$to_formant()
times <- seq(0.1, 0.5, by = 0.001)

# Tier 1: Loop
system.time({
  f1_values <- sapply(times, function(t) {
    formant$get_value_at_time(1, t, "hertz")
  })
})
#>    user  system elapsed 
#>   0.012   0.000   0.012
# one R->C crossing per time point

# Tier 3: Vectorized
system.time({
  f1_values <- get_formants_at_times(formant, times, formant_numbers = 1)
})
#>    user  system elapsed 
#>       0       0       0
# one R->C crossing for the whole vector — this is where batching pays off
```

------------------------------------------------------------------------

### Decision Tree: Which Tier Should I Use?

    Are you processing < 10 files?
    ├─ YES → Use Tier 1 (standard API)
    └─ NO ↓

    Are you processing < 100 files?
    ├─ YES → Use Tier 2 (direct API) if profiling shows it helps
    └─ NO ↓

    Are you processing > 100 files?
    ├─ Single machine → Use Tier 3 batch + parallel
    └─ Cluster → Use Tier 2 direct + your cluster manager

------------------------------------------------------------------------

### Best Practices

#### 1. Start with Tier 1, Optimize Later

Don’t prematurely optimize. Use the standard API first:

``` r

# Good: Clear and maintainable
pitch <- sound$to_pitch()$smooth()
mean_f0 <- pitch$get_mean(0, 0, "hertz")
```

Only move to Tier 2/3 when: - Profiling your own code shows a
bottleneck - You’re processing \>100 files - Runtime matters for your
workflow

#### 2. Batch Similar Operations

``` r

# Tier 1: Multiple individual queries
f1 <- formant$get_value_at_time(1, 0.5, "hertz")
f2 <- formant$get_value_at_time(2, 0.5, "hertz")
f3 <- formant$get_value_at_time(3, 0.5, "hertz")
f4 <- formant$get_value_at_time(4, 0.5, "hertz")

# Tier 2: Single batch query
formants <- get_formants_direct(formant, time = 0.5)
```

#### 3. Reuse Pointers in Loops

``` r

# Avoid: Repeated single-value queries in a loop
for (time in times) {
  val <- get_pitch_value_direct(pitch, time)
}

# Prefer: One call for the whole vector of times
# (get_pitch_at_times() takes the Pitch object itself, not an XPtr — it
# extracts the pointer internally)
values <- get_pitch_at_times(pitch, times)
```

#### 4. Choose a Core Count That Fits Your Workload

Not all workloads scale linearly with core count, and small files can
make parallelization overhead outweigh any benefit. Use
[`benchmark_parallel()`](https://humlab-speech.github.io/pladdrr/reference/benchmark_parallel.md)
to test a range of core counts on a representative subset of your own
files before committing to a setting for a full run:

``` r

# Test different core counts on a subset
benchmark_results <- benchmark_parallel(
  files[1:10],  # Use subset for a quick test
  function(s) s$to_pitch()$get_mean(0, 0, "hertz"),
  core_counts = c(1, 2)  # extend to c(1, 2, 4, 8) etc. up to your machine's cores
)
#> Testing with 1 core(s)...
#> Using single core (set n_cores > 1 for parallel processing)
#> Testing with 2 core(s)...
#> Processing 10 files using 2 cores (2 thread(s)/worker)

print(benchmark_results)
#>   cores   time_sec  speedup
#> 1     1 0.05385995 1.000000
#> 2     2 0.06467605 0.832765
# Inspect the returned table to see where returns diminish on your machine
```

#### 5. Combine Batch and Parallel Processing

``` r

# Define the per-file constants *inside* the worker function rather than
# capturing them from the enclosing environment. On Windows (and on macOS,
# where analyze_files_parallel() also uses a PSOCK cluster to avoid known
# fork/event-loop issues), each worker is a separate R process that only
# receives the function and file path — free variables referenced from the
# calling environment are not automatically exported and would error with
# "object not found" unless passed via clusterExport() or defined locally
# like this.
analyze_files_parallel(files, function(sound) {
  start_times <- c(0.1, 0.3)
  end_times <- c(0.2, 0.4)
  analysis_times <- seq(0.01, 0.05, by = 0.01)

  # Use batch operations within each worker
  parts <- sound$extract_parts_batch(start_times, end_times)
  formants <- sound_to_formant_batch(parts)

  # Vectorized queries
  lapply(formants, function(f) {
    get_formants_at_times(f, analysis_times)
  })
}, n_cores = 2)
#> Processing 20 files using 2 cores (2 thread(s)/worker)
#> [[1]]
#> [[1]][[1]]
#> [[1]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[1]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[1]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[1]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[1]][[2]]
#> [[1]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[1]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[1]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[1]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[2]]
#> [[2]][[1]]
#> [[2]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[2]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[2]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[2]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[2]][[2]]
#> [[2]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[2]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[2]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[2]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[3]]
#> [[3]][[1]]
#> [[3]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[3]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[3]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[3]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[3]][[2]]
#> [[3]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[3]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[3]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[3]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[4]]
#> [[4]][[1]]
#> [[4]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[4]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[4]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[4]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[4]][[2]]
#> [[4]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[4]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[4]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[4]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[5]]
#> [[5]][[1]]
#> [[5]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[5]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[5]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[5]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[5]][[2]]
#> [[5]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[5]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[5]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[5]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[6]]
#> [[6]][[1]]
#> [[6]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[6]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[6]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[6]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[6]][[2]]
#> [[6]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[6]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[6]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[6]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[7]]
#> [[7]][[1]]
#> [[7]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[7]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[7]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[7]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[7]][[2]]
#> [[7]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[7]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[7]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[7]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[8]]
#> [[8]][[1]]
#> [[8]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[8]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[8]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[8]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[8]][[2]]
#> [[8]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[8]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[8]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[8]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[9]]
#> [[9]][[1]]
#> [[9]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[9]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[9]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[9]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[9]][[2]]
#> [[9]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[9]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[9]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[9]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[10]]
#> [[10]][[1]]
#> [[10]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[10]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[10]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[10]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[10]][[2]]
#> [[10]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[10]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[10]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[10]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[11]]
#> [[11]][[1]]
#> [[11]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[11]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[11]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[11]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[11]][[2]]
#> [[11]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[11]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[11]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[11]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[12]]
#> [[12]][[1]]
#> [[12]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[12]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[12]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[12]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[12]][[2]]
#> [[12]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[12]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[12]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[12]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[13]]
#> [[13]][[1]]
#> [[13]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[13]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[13]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[13]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[13]][[2]]
#> [[13]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[13]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[13]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[13]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[14]]
#> [[14]][[1]]
#> [[14]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[14]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[14]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[14]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[14]][[2]]
#> [[14]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[14]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[14]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[14]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[15]]
#> [[15]][[1]]
#> [[15]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[15]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[15]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[15]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[15]][[2]]
#> [[15]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[15]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[15]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[15]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[16]]
#> [[16]][[1]]
#> [[16]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[16]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[16]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[16]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[16]][[2]]
#> [[16]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[16]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[16]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[16]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[17]]
#> [[17]][[1]]
#> [[17]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[17]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[17]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[17]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[17]][[2]]
#> [[17]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[17]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[17]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[17]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[18]]
#> [[18]][[1]]
#> [[18]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[18]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[18]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[18]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[18]][[2]]
#> [[18]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[18]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[18]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[18]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[19]]
#> [[19]][[1]]
#> [[19]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[19]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[19]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[19]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[19]][[2]]
#> [[19]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[19]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[19]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[19]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
#> 
#> 
#> 
#> [[20]]
#> [[20]][[1]]
#> [[20]][[1]]$F1
#> [1]       NA       NA 420.8500 420.7663 421.1240
#> 
#> [[20]][[1]]$F2
#> [1]       NA       NA 464.7808 464.6990 465.0480
#> 
#> [[20]][[1]]$F3
#> [1]       NA       NA 2999.369 2975.049 3042.348
#> 
#> [[20]][[1]]$F4
#> [1]       NA       NA 4205.872 4190.150 4248.532
#> 
#> 
#> [[20]][[2]]
#> [[20]][[2]]$F1
#> [1]       NA       NA 421.0817 421.0195 420.9680
#> 
#> [[20]][[2]]$F2
#> [1]       NA       NA 465.0067 464.9466 464.8963
#> 
#> [[20]][[2]]$F3
#> [1]       NA       NA 3031.412 3089.364 3011.475
#> 
#> [[20]][[2]]$F4
#> [1]       NA       NA 4239.889 4211.581 4289.379
```

------------------------------------------------------------------------

### Troubleshooting

#### Parallel Processing Issues

**macOS/Linux:** - Uses
[`mclapply()`](https://rdrr.io/r/parallel/mclapply.html) (fork-based
parallelism) - Shares memory between processes

**Windows:** - Uses
[`parLapply()`](https://rdrr.io/r/parallel/clusterApply.html)
(socket-based parallelism) - Creates separate R processes - May need to
export objects explicitly

**Memory constraints:** - Each core loads files independently - With 4
cores and 100MB files, plan for roughly 400MB RAM - Reduce `n_cores` if
you hit memory limits

#### Runtime Not Improving?

If parallelizing or batching your own workload isn’t helping, check:

1.  **I/O bound?** - File reading may be the bottleneck, not analysis
2.  **Small files?** - Parallelization overhead can exceed any benefit
3.  **Disk speed?** - Try processing from SSD instead of HDD
4.  **CPU usage** - Use `htop` or Task Manager to see whether cores are
    saturated

------------------------------------------------------------------------

### Summary Table

| Tier | Use Case | Functions | Learning Curve |
|----|----|----|----|
| 1 | Interactive, \<10 files | `sound$to_pitch()` | Easy |
| 2 | Loops, 10-100 files | [`to_pitch_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_pitch_direct.md) | Medium |
| 3 | Production, \>100 files | [`sound_to_pitch_batch()`](https://humlab-speech.github.io/pladdrr/reference/sound_to_pitch_batch.md) | Medium |
| 3+ | Large datasets | [`extract_pitch_parallel()`](https://humlab-speech.github.io/pladdrr/reference/extract_pitch_parallel.md) | Easy |

------------------------------------------------------------------------

### Further Reading

- [`vignette("getting-started")`](https://humlab-speech.github.io/pladdrr/articles/getting-started.md) -
  Introduction to pladdrr
- [`?analyze_files_parallel`](https://humlab-speech.github.io/pladdrr/reference/analyze_files_parallel.md) -
  Parallel processing documentation
- [`?get_pitch_stats_direct`](https://humlab-speech.github.io/pladdrr/reference/get_pitch_stats_direct.md) -
  Direct API reference
