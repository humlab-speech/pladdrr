# Benchmark: Batch/Vectorized Operations vs Individual Calls
# Demonstrates the performance improvement from looping in C++ vs R

library(pladdrr)

cat("=== Batch/Vectorized Operations Benchmark ===\n\n")

# Create test sound (longer for meaningful benchmarks)
sound <- sound_generate_tone(440, duration = 3.0, sample_rate = 44100)

cat("Test sound: 3 seconds, 44.1kHz\n\n")

# ============================================================================
# Phase 1: Sound Window Operations (AVQI speedup)
# ============================================================================

cat("--- Phase 1: Sound Window Operations ---\n")

# 500 windows (typical for AVQI analysis)
n_windows <- 500
window_duration <- 0.03
starts <- seq(0, sound$get_duration() - window_duration, length.out = n_windows)
ends <- starts + window_duration

cat(sprintf("Testing %d windows of %.3fs each\n", n_windows, window_duration))

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  library(microbenchmark)

  mb <- microbenchmark(
    batch = sound$get_power_windows(starts, ends),
    loop = vapply(seq_along(starts), function(i)
             sound$get_power(starts[i], ends[i]), numeric(1)),
    times = 10
  )

  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop"]) /
                                     median(mb$time[mb$expr == "batch"])))
} else {
  # Fallback without microbenchmark
  t1 <- system.time({
    for (i in 1:5) sound$get_power_windows(starts, ends)
  })[3] / 5

  t2 <- system.time({
    for (i in 1:5) {
      vapply(seq_along(starts), function(j) sound$get_power(starts[j], ends[j]), numeric(1))
    }
  })[3] / 5

  cat(sprintf("Batch: %.4fs, Loop: %.4fs, Speedup: %.1fx\n\n", t1, t2, t2/t1))
}

# ============================================================================
# Phase 2: Value Extraction (Tremor analysis speedup)
# ============================================================================

cat("--- Phase 2: Value Extraction ---\n")

times <- seq(0.01, sound$get_duration() - 0.01, by = 0.001)
cat(sprintf("Getting values at %d time points\n", length(times)))

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  mb <- microbenchmark(
    batch = sound$get_values_at_times(times),
    loop = vapply(times, function(t) sound$get_value_at_time(t), numeric(1)),
    times = 5
  )
  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop"]) /
                                     median(mb$time[mb$expr == "batch"])))
}

# ============================================================================
# Phase 3: Pitch Vector Operations (DSI speedup)
# ============================================================================

cat("--- Phase 3: Pitch Vector Operations ---\n")

pitch <- sound$to_pitch(0.01, 75, 500)
n_frames <- pitch$get_number_of_frames()
cat(sprintf("Pitch object: %d frames\n", n_frames))

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  times_vec <- pitch$get_times_vector()

  mb <- microbenchmark(
    batch_mask = pitch$get_voiced_mask(),
    loop_mask = vapply(seq_len(n_frames), function(i) {
      t <- pitch$get_time_from_frame(i)
      v <- pitch$get_value_at_time(t)
      !is.na(v)
    }, logical(1)),
    times = 10
  )
  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop_mask"]) /
                                     median(mb$time[mb$expr == "batch_mask"])))
}

# ============================================================================
# Phase 4: Harmonicity Batch Stats (VQ speedup)
# ============================================================================

cat("--- Phase 4: Harmonicity Batch Stats ---\n")

hnr <- sound$to_harmonicity_ac(0.01, 75)
cat(sprintf("Harmonicity object: %d frames\n", hnr$get_number_of_frames()))

# Multiple windows for multi-band analysis
n_bands <- 20
band_starts <- seq(0.1, 2.0, length.out = n_bands)
band_ends <- band_starts + 0.5

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  mb <- microbenchmark(
    batch = hnr$get_statistics_batch(band_starts, band_ends, c("mean", "min", "max")),
    loop = {
      result <- matrix(NA, n_bands, 3)
      for (i in seq_len(n_bands)) {
        result[i, 1] <- hnr$get_mean(band_starts[i], band_ends[i])
        result[i, 2] <- hnr$get_minimum(band_starts[i], band_ends[i])
        result[i, 3] <- hnr$get_maximum(band_starts[i], band_ends[i])
      }
      result
    },
    times = 20
  )
  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop"]) /
                                     median(mb$time[mb$expr == "batch"])))
}

# ============================================================================
# Phase 6: Spectrum Vector Extraction (Pharyngeal speedup)
# ============================================================================

cat("--- Phase 6: Spectrum Vector Extraction ---\n")

spectrum <- sound$to_spectrum()
n_bins <- spectrum$get_number_of_bins()
cat(sprintf("Spectrum: %d frequency bins\n", n_bins))

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  mb <- microbenchmark(
    batch = spectrum$get_power_vector(),
    loop = vapply(seq_len(n_bins), function(i) {
      re <- spectrum$get_real_value_in_bin(i)
      im <- spectrum$get_imaginary_value_in_bin(i)
      re^2 + im^2
    }, numeric(1)),
    times = 10
  )
  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop"]) /
                                     median(mb$time[mb$expr == "batch"])))
}

# ============================================================================
# Formant Track Extraction
# ============================================================================

cat("--- Formant Track Extraction ---\n")

formant <- sound$to_formant_burg(0.01, 5, 5500)
n_formant_frames <- formant$get_number_of_frames()
cat(sprintf("Formant: %d frames\n", n_formant_frames))

if (requireNamespace("microbenchmark", quietly = TRUE)) {
  times_vec <- formant$get_times_vector()

  mb <- microbenchmark(
    batch = formant$get_formant_track(1),
    loop = vapply(times_vec, function(t)
             formant$get_value_at_time(1, t), numeric(1)),
    times = 10
  )
  print(mb)
  cat(sprintf("Speedup: %.1fx\n\n", median(mb$time[mb$expr == "loop"]) /
                                     median(mb$time[mb$expr == "batch"])))
}

cat("=== Benchmark Complete ===\n")
