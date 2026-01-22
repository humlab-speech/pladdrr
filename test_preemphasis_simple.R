#!/usr/bin/env Rscript
# Simple pre-emphasis test
library(pladdrr)

# Small test signal
signal <- c(1, 2, 3, 4, 5)
cat("Original signal:\n")
print(signal)

# Create Sound
snd <- Sound$from_values(signal, 16000)

# Pre-emphasize with cutoff frequency 50 Hz
snd$pre_emphasize(50)

result <- snd$as_matrix()[, 1]
cat("\nAfter pre-emphasis:\n")
print(result)

# Manual calculation
emphasis_factor <- exp(-2 * pi * 50 / 16000)
cat(sprintf("\nemphasisFactor: %.10f\n", emphasis_factor))

manual <- signal
for (i in length(manual):2) {
  manual[i] <- manual[i] - emphasis_factor * manual[i - 1]
}
cat("\nManual calculation:\n")
print(manual)

cat("\nDifference:\n")
print(result - manual)
cat(sprintf("\nMax difference: %.2e\n", max(abs(result - manual))))
