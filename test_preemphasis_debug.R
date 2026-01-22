#!/usr/bin/env Rscript
# Debug pre-emphasis
library(pladdrr)

# Small test signal
signal <- c(1, 2, 3, 4, 5)
cat("Original signal:\n")
print(signal)

# Create Sound
snd <- Sound$from_values(signal, 16000)

cat("\nSound info before pre-emphasis:\n")
cat(sprintf("Duration: %.6f s\n", snd$get_duration()))
cat(sprintf("Num samples: %d\n", snd$get_number_of_samples()))
cat(sprintf("Num channels: %d\n", snd$get_number_of_channels()))

# Get data before
data_before <- snd$as_matrix()
cat("\nData before pre-emphasis:\n")
print(data_before)

# Pre-emphasize
snd$pre_emphasize(50)

cat("\nSound info after pre-emphasis:\n")
cat(sprintf("Duration: %.6f s\n", snd$get_duration()))
cat(sprintf("Num samples: %d\n", snd$get_number_of_samples()))
cat(sprintf("Num channels: %d\n", snd$get_number_of_channels()))

# Get data after
data_after <- snd$as_matrix()
cat("\nData after pre-emphasis:\n")
print(data_after)
