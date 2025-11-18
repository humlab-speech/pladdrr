#!/usr/bin/env Rscript
# Create test.wav file for benchmarks

# Install tuneR if needed
if (!requireNamespace("tuneR", quietly = TRUE)) {
  install.packages("tuneR", repos = "https://cloud.r-project.org", quiet = TRUE)
}

library(tuneR)

# Create a simple 1-second 440 Hz sine wave
sr <- 44100
duration <- 1
t <- seq(0, duration, length.out = sr * duration)
signal <- sin(2 * pi * 440 * t) * 0.5

# Create Wave object
wave_obj <- Wave(left = as.integer(signal * 32767), samp.rate = sr, bit = 16)

# Write to file
output_path <- "inst/extdata/test.wav"
writeWave(wave_obj, output_path)

cat("✓ Created", output_path, "\n")
cat("File size:", file.info(output_path)$size, "bytes\n")
