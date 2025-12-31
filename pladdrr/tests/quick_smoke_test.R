#!/usr/bin/env Rscript
#
# Quick Smoke Test
#
# Verifies that all three implementations (AVQI, DSI, Tremor) can run
# without errors using test data.

suppressPackageStartupMessages({
  library(speakr)
})

cat("=============================================================\n")
cat("QUICK SMOKE TEST\n")
cat("=============================================================\n\n")

# Configuration
PLABENCH_DIR <- "/Users/frkkan96/Documents/src/plabench"
TEST_DATA_DIR <- file.path(PLABENCH_DIR, "signalfiles")

test_passed <- 0
test_failed <- 0

# =============================================================================
# Test AVQI
# =============================================================================

cat("=== Testing AVQI ===\n")

avqi_dir <- file.path(TEST_DATA_DIR, "AVQI", "input")

if (dir.exists(avqi_dir)) {
  cs_files <- list.files(avqi_dir, pattern = "^cs.*\\.wav$", full.names = TRUE)
  sv_files <- list.files(avqi_dir, pattern = "^sv.*\\.wav$", full.names = TRUE)

  if (length(cs_files) > 0 && length(sv_files) > 0) {
    tryCatch({
      cat("Running compute_avqi()... ")

      result <- compute_avqi(
        sound = sv_files[1],
        type = "combined",
        speech_sound = cs_files[1],
        gender = "unknown",
        verbose = FALSE
      )

      # Verify results
      stopifnot(!is.null(result))
      stopifnot(!is.na(result$avqi))
      stopifnot(result$avqi >= 0 && result$avqi <= 10)
      stopifnot(!is.na(result$cpps))
      stopifnot(!is.na(result$hnr))

      cat("✓ PASSED\n")
      cat(sprintf("  AVQI: %.3f\n", result$avqi))
      cat(sprintf("  CPPS: %.2f dB\n", result$cpps))
      cat(sprintf("  HNR: %.2f dB\n", result$hnr))
      cat(sprintf("  Shimmer: %.2f%%\n", result$shimmer_local))
      cat("\n")

      test_passed <- test_passed + 1

    }, error = function(e) {
      cat("✗ FAILED\n")
      cat(sprintf("  Error: %s\n\n", e$message))
      test_failed <- test_failed + 1
    })
  } else {
    cat("⚠ SKIPPED (test files not found)\n\n")
  }
} else {
  cat("⚠ SKIPPED (test directory not found)\n\n")
}

# =============================================================================
# Test DSI
# =============================================================================

cat("=== Testing DSI ===\n")

dsi_dir <- file.path(TEST_DATA_DIR, "DSI", "input")

if (dir.exists(dsi_dir)) {
  mpt_files <- list.files(dsi_dir, pattern = "^mpt.*\\.wav$", full.names = TRUE)
  fh_files <- list.files(dsi_dir, pattern = "^fh.*\\.wav$", full.names = TRUE)
  im_files <- list.files(dsi_dir, pattern = "^im.*\\.wav$", full.names = TRUE)
  ppq_files <- list.files(dsi_dir, pattern = "^ppq.*\\.wav$", full.names = TRUE)

  if (length(mpt_files) > 0 && length(fh_files) > 0 &&
      length(im_files) > 0 && length(ppq_files) > 0) {

    tryCatch({
      cat("Loading and concatenating files... ")

      # Load and concatenate each file type
      mpt_sound <- Sound$new(mpt_files[1])
      for (i in seq_along(mpt_files)[-1]) {
        mpt_sound <- mpt_sound$concatenate(Sound$new(mpt_files[i]))
      }

      fh_sound <- Sound$new(fh_files[1])
      for (i in seq_along(fh_files)[-1]) {
        fh_sound <- fh_sound$concatenate(Sound$new(fh_files[i]))
      }

      im_sound <- Sound$new(im_files[1])
      for (i in seq_along(im_files)[-1]) {
        im_sound <- im_sound$concatenate(Sound$new(im_files[i]))
      }

      ppq_sound <- Sound$new(ppq_files[1])
      for (i in seq_along(ppq_files)[-1]) {
        ppq_sound <- ppq_sound$concatenate(Sound$new(ppq_files[i]))
      }

      # Combine all
      combined <- mpt_sound$concatenate(fh_sound)
      combined <- combined$concatenate(im_sound)
      combined <- combined$concatenate(ppq_sound)

      cat("done\n")
      cat("Running compute_dsi()... ")

      result <- compute_dsi(
        sound = combined,
        type = "sustained",
        gender = "unknown",
        verbose = FALSE
      )

      # Verify results
      stopifnot(!is.null(result))
      stopifnot(!is.na(result$dsi))
      stopifnot(!is.na(result$mpt))
      stopifnot(!is.na(result$f0_high))

      cat("✓ PASSED\n")
      cat(sprintf("  DSI: %.2f\n", result$dsi))
      cat(sprintf("  MPT: %.2f s\n", result$mpt))
      cat(sprintf("  F0-high: %.1f Hz\n", result$f0_high))
      cat(sprintf("  I-low: %.2f dB\n", result$i_low))
      cat(sprintf("  Jitter: %.3f%%\n", result$jitter_ppq5))
      cat("\n")

      test_passed <- test_passed + 1

    }, error = function(e) {
      cat("✗ FAILED\n")
      cat(sprintf("  Error: %s\n\n", e$message))
      test_failed <- test_failed + 1
    })
  } else {
    cat("⚠ SKIPPED (test files not found)\n\n")
  }
} else {
  cat("⚠ SKIPPED (test directory not found)\n\n")
}

# =============================================================================
# Test Tremor
# =============================================================================

cat("=== Testing Tremor ===\n")

# Use one of the DSI sustained vowel files for tremor test
if (exists("ppq_files") && length(ppq_files) > 0) {
  tryCatch({
    cat("Running analyze_tremor()... ")

    result <- analyze_tremor(
      sound = ppq_files[1],
      min_pitch = 60,
      max_pitch = 350,
      verbose = FALSE
    )

    # Verify results
    stopifnot(!is.null(result))
    stopifnot(!is.na(result$FTrF))
    stopifnot(!is.na(result$ATrF))

    cat("✓ PASSED\n")
    cat(sprintf("  Frequency tremor: %.2f Hz (intensity: %.2f%%)\n",
                result$FTrF, result$FTrI))
    cat(sprintf("  Amplitude tremor: %.2f Hz (intensity: %.2f%%)\n",
                result$ATrF, result$ATrI))
    cat(sprintf("  F-cyclicality: %.2f\n", result$FTrC))
    cat(sprintf("  A-cyclicality: %.2f\n", result$ATrC))
    cat("\n")

    test_passed <- test_passed + 1

  }, error = function(e) {
    cat("✗ FAILED\n")
    cat(sprintf("  Error: %s\n\n", e$message))
    test_failed <- test_failed + 1
  })
} else {
  cat("⚠ SKIPPED (no suitable test file found)\n\n")
}

# =============================================================================
# Summary
# =============================================================================

cat("=============================================================\n")
cat("SMOKE TEST SUMMARY\n")
cat("=============================================================\n")
cat(sprintf("Tests passed: %d\n", test_passed))
cat(sprintf("Tests failed: %d\n", test_failed))
cat(sprintf("Total tests:  %d\n", test_passed + test_failed))
cat("\n")

if (test_failed == 0) {
  cat("✓ All smoke tests passed!\n")
  cat("\n")
  cat("Next steps:\n")
  cat("1. Run full cross-validation tests:\n")
  cat("   Rscript tests/test_cross_validation.R\n")
  cat("\n")
  cat("2. Generate Praat reference data:\n")
  cat("   ./tests/generate_praat_reference.sh\n")
  cat("\n")
  cat("3. Compare with Python/plabench:\n")
  cat("   python3 -m pytest plabench/tests/\n")
  cat("\n")
  quit(status = 0)
} else {
  cat("✗ Some tests failed. Please check the errors above.\n")
  cat("\n")
  quit(status = 1)
}
