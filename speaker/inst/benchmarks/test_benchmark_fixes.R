#!/usr/bin/env Rscript
# Test script to verify benchmarks work correctly

library(speaker)
library(bench)

cat("================================================================================\n")
cat("Testing Benchmark Fixes\n")
cat("================================================================================\n\n")

# Test 1: Simple benchmark with fresh Sound creation
cat("Test 1: Benchmark with synthetic audio (create_tone)...\n")
result1 <- tryCatch({
  bench::mark(
    pitch = {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      sound$to_pitch()
    },
    formants = {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      sound$to_formant_burg()
    },
    intensity = {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      sound$to_intensity()
    },
    iterations = 3,
    check = FALSE
  )
}, error = function(e) {
  cat("  ✗ Error:", e$message, "\n")
  NULL
})

if (!is.null(result1)) {
  cat("  ✓ Benchmark completed successfully\n")
  print(result1[, c("expression", "min", "median", "itr/sec")])
} else {
  cat("  ✗ Benchmark failed\n")
}

cat("\n")

# Test 2: Verify no .xptr errors across multiple iterations
cat("Test 2: Multiple iterations (checking for .xptr stability)...\n")
error_count <- 0
success_count <- 0

for (i in 1:5) {
  result <- tryCatch({
    sound <- Sound$create_tone(0.5, 440, 44100, 0.5)
    pitch <- sound$to_pitch()
    TRUE
  }, error = function(e) {
    error_count <<- error_count + 1
    FALSE
  })
  
  if (result) {
    success_count <- success_count + 1
  }
}

cat("  Iterations:", 5, "\n")
cat("  Successful:", success_count, "\n")
cat("  Errors:", error_count, "\n")

if (error_count == 0) {
  cat("  ✓ All iterations successful - no .xptr errors\n")
} else {
  cat("  ✗ Some iterations failed\n")
}

cat("\n")

# Summary
cat("================================================================================\n")
cat("SUMMARY\n")
cat("================================================================================\n")

if (!is.null(result1) && error_count == 0) {
  cat("✅ ALL TESTS PASSED\n")
  cat("   Benchmarks work correctly with bench::mark()\n")
  cat("   No .xptr errors detected\n")
  cat("   Ready for production use\n")
} else {
  cat("⚠️  SOME TESTS FAILED\n")
  cat("   Review errors above\n")
}

cat("\n")
