#' Native I/O Performance Benchmark
#' 
#' Compares native Praat file reading vs av package fallback
#' for WAV files of different sizes.

library(pladdrr)

benchmark_native_io <- function(file_path, n_iterations = 100) {
  cat("\nBenchmarking:", basename(file_path), "\n")
  cat("File size:", round(file.info(file_path)$size / 1024, 1), "KB\n")
  
  # Warm-up
  snd <- Sound$new(file_path)
  cat("Duration:", snd$get_duration(), "sec\n")
  cat("Sample rate:", snd$get_sampling_frequency(), "Hz\n")
  cat("Channels:", snd$get_number_of_channels(), "\n\n")
  
  # Benchmark read
  times_read <- replicate(n_iterations, {
    system.time(Sound$new(file_path))[3]
  })
  
  # Benchmark write
  tmp <- tempfile(fileext = ".wav")
  times_write <- replicate(n_iterations, {
    system.time(snd$save(tmp))[3]
  })
  unlink(tmp)
  
  # Results
  cat("READ Performance (", n_iterations, " iterations):\n", sep="")
  cat("  Mean:  ", round(mean(times_read) * 1000, 2), "ms\n")
  cat("  Median:", round(median(times_read) * 1000, 2), "ms\n")
  cat("  Min:   ", round(min(times_read) * 1000, 2), "ms\n")
  cat("  Max:   ", round(max(times_read) * 1000, 2), "ms\n")
  
  cat("\nWRITE Performance (", n_iterations, " iterations):\n", sep="")
  cat("  Mean:  ", round(mean(times_write) * 1000, 2), "ms\n")
  cat("  Median:", round(median(times_write) * 1000, 2), "ms\n")
  cat("  Min:   ", round(min(times_write) * 1000, 2), "ms\n")
  cat("  Max:   ", round(max(times_write) * 1000, 2), "ms\n")
  
  invisible(list(read = times_read, write = times_write))
}

# Example usage
if (interactive()) {
  # Benchmark a WAV file
  wav_file <- system.file("extdata", "test.wav", package = "pladdrr")
  if (file.exists(wav_file)) {
    results <- benchmark_native_io(wav_file, n_iterations = 100)
  }
}
