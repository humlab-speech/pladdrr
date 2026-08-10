# Batch Process Sounds in Parallel

Apply analysis to pre-loaded Sound objects in parallel. Use when sounds
are already in memory.

## Usage

``` r
process_sounds_parallel(
  sounds,
  analysis_func,
  n_cores = NULL,
  threads_per_worker = NULL,
  ...
)
```

## Arguments

- sounds:

  List of Sound objects or external pointers

- analysis_func:

  Function. Analysis function to apply. Should accept a Sound
  object/pointer and return results.

- n_cores:

  Integer. Number of CPU cores (default: auto)

- threads_per_worker:

  Integer or \`NULL\`. C++ threads each worker may use for Praat
  kernels. \`NULL\` (default) auto-divides cores among workers to avoid
  oversubscription; set \`1\` to force single-threaded workers.

- ...:

  Additional arguments passed to analysis_func

## Value

List of results

## Examples

``` r
# \donttest{
sounds <- list(
  Sound$create_tone(frequency = 220, duration = 0.2),
  Sound$create_tone(frequency = 440, duration = 0.2)
)

# Process using at most 2 cores (CRAN example policy)
results <- process_sounds_parallel(sounds, function(s) {
  pitch <- s$to_pitch()
  pitch$get_mean(0, 0, "hertz")
}, n_cores = 2)
#> Processing 2 sounds using 2 cores (2 thread(s)/worker)
# }
```
