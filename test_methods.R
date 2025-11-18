#!/usr/bin/env Rscript
# Test Sound methods availability

library(speaker)

# Create a test sound
sound <- Sound$from_values(c(0, 0.5, 1.0, 0.5, 0), sampling_rate = 16000)

cat("Testing Sound object creation:\n")
print(class(sound))

cat("\nTesting if methods exist:\n")
cat("  names(sound):\n")
print(head(names(sound), 20))

cat("\n  ls(sound):\n")
print(head(ls(sound), 20))

cat("\nTesting method calls directly:\n")

# Test get_rms
cat("  get_rms: ")
tryCatch({
  rms <- sound$get_rms(from_time = 0, to_time = 0)
  cat(sprintf("✓ Works! Value = %.4f\n", rms))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

# Test get_energy
cat("  get_energy: ")
tryCatch({
  energy <- sound$get_energy(from_time = 0, to_time = 0)
  cat(sprintf("✓ Works! Value = %.4f\n", energy))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

# Test get_power
cat("  get_power: ")
tryCatch({
  power <- sound$get_power(from_time = 0, to_time = 0)
  cat(sprintf("✓ Works! Value = %.4f\n", power))
}, error = function(e) {
  cat(sprintf("✗ Error: %s\n", e$message))
})

cat("\nChecking for method existence in class definition:\n")
sound_class <- Sound
print(names(sound_class$public_methods))
