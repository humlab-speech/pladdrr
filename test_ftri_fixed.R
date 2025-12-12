#!/usr/bin/env Rscript
# Test FTrI after fixing Sound$from_values with start_time

library(pladdrr)

cat("=== Testing FTrI Implementation ===\n\n")

# Load test file
snd <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")

# Run tremor analysis
result <- analyze_tremor(snd, verbose = TRUE)

cat("\n=== RESULTS ===\n")
cat(sprintf("FTrI: %.4f%% (expected: 2.1697%%)\n", result$FTrI))
cat(sprintf("Error: %.2f%%\n", abs(result$FTrI - 2.1697) / 2.1697 * 100))

# Test Sound$from_values directly
cat("\n=== Testing Sound$from_values ===\n")
test_values <- sin(2 * pi * seq(0, 1, length.out = 100) * 5)
test_sound <- Sound$from_values(test_values, sampling_rate = 100, start_time = 0.5)
cat(sprintf("Created Sound: duration=%.3f s, fs=%.1f Hz\n",
            test_sound$get_duration(),
            test_sound$get_sampling_frequency()))
cat(sprintf("Value at start (0.5s): %.4f (expected ~0)\n",
            test_sound$get_value_at_time(0.5)))
cat(sprintf("Value at 0.75s: %.4f (expected ~1)\n",
            test_sound$get_value_at_time(0.75)))

cat("\n✅ If all tests pass, FTrI implementation is complete!\n")
