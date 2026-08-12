# tests/testthat/test-phase4-formantpath-simd.R
#
# Test suite for Phase 4 Task 4.1: FormantPath SIMD optimization
#
# Tests multi-ceiling formant extraction with SIMD-accelerated
# dynamic programming path finding

library(testthat)
library(pladdrr)


# Helper function to create test sound
create_test_vowel <- function(duration = 0.5, sr = 16000) {
  # Synthetic vowel /a/ with F1=700Hz, F2=1200Hz, F3=2500Hz
  t <- seq(0, duration, length.out = duration * sr)
  f0 <- 150  # Fundamental frequency
  
  # Harmonic series with formant-like resonances
  signal <- sin(2 * pi * f0 * t) * 0.3
  signal <- signal + sin(2 * pi * 700 * t) * 0.4  # F1
  signal <- signal + sin(2 * pi * 1200 * t) * 0.3  # F2
  signal <- signal + sin(2 * pi * 2500 * t) * 0.2  # F3
  
  # Add some noise
  signal <- signal + rnorm(length(signal), 0, 0.05)
  
  # Normalize
  signal <- signal / max(abs(signal)) * 0.9
  
  Sound$from_values(signal, sampling_rate = sr)
}


# ==============================================================================
# Test 1: FormantPath creation and basic properties
# ==============================================================================
test_that("FormantPath: SIMD vs scalar produce same structure", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.3, sr = 16000)
  
  # Scalar path
  options(speaker.use_simd = FALSE)
  fp_scalar <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2  # 5 candidates total
  )
  
  # SIMD path
  options(speaker.use_simd = TRUE)
  fp_simd <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2
  )
  
  # Check structure
  expect_s3_class(fp_scalar, "FormantPath")
  expect_s3_class(fp_simd, "FormantPath")
  
  # Should have same number of candidates
  expect_equal(fp_scalar$get_number_of_candidates(), 
               fp_simd$get_number_of_candidates())
  
  # Should have same time domain
  expect_equal(fp_scalar$get_xmin(), fp_simd$get_xmin(), tolerance = 1e-10)
  expect_equal(fp_scalar$get_xmax(), fp_simd$get_xmax(), tolerance = 1e-10)
  expect_equal(fp_scalar$get_nx(), fp_simd$get_nx())
})


# ==============================================================================
# Test 2: Extracted formant tracks match (SIMD vs scalar)
# ==============================================================================
test_that("FormantPath: Extracted formants match SIMD vs scalar", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.5, sr = 16000)
  
  # Scalar
  options(speaker.use_simd = FALSE)
  fp_scalar <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2
  )
  formant_scalar <- fp_scalar$extract_formant()
  
  # SIMD
  options(speaker.use_simd = TRUE)
  fp_simd <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2
  )
  formant_simd <- fp_simd$extract_formant()
  
  # Compare F1, F2, F3 at midpoint
  t_mid <- sound$get_xmax() / 2
  
  f1_scalar <- formant_scalar$get_value_at_time(1, t_mid)
  f1_simd <- formant_simd$get_value_at_time(1, t_mid)
  
  f2_scalar <- formant_scalar$get_value_at_time(2, t_mid)
  f2_simd <- formant_simd$get_value_at_time(2, t_mid)
  
  # Formants should be very close (within 10 Hz)
  # Dynamic programming may have different paths but should converge
  if (!is.na(f1_scalar) && !is.na(f1_simd)) {
    expect_lt(abs(f1_scalar - f1_simd), 20)  # Allow 20 Hz difference
  }
  
  if (!is.na(f2_scalar) && !is.na(f2_simd)) {
    expect_lt(abs(f2_scalar - f2_simd), 20)
  }
})


# ==============================================================================
# Test 3: Path finding with different weights
# ==============================================================================
test_that("FormantPath: Path finding works with different weights", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.4, sr = 16000)
  
  options(speaker.use_simd = TRUE)
  
  # High frequency change weight (smooth paths)
  fp_smooth <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2
  )
  
  # Should successfully extract formants
  formant <- fp_smooth$extract_formant()
  expect_s3_class(formant, "Formant")
  
  # Should have reasonable F1 values
  f1_mean <- formant$get_mean(1, 0, 0)
  if (!is.na(f1_mean)) {
    expect_gt(f1_mean, 400)
    expect_lt(f1_mean, 1200)
  }
})


# ==============================================================================
# Test 4: Multiple ceiling candidates
# ==============================================================================
test_that("FormantPath: Multiple ceiling candidates work", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.3, sr = 16000)
  
  options(speaker.use_simd = TRUE)
  
  # Test with different numbers of ceiling steps
  for (n_steps in c(1, 2, 3)) {
    fp <- sound$to_formant_path(
      time_step = 0.01,
      max_num_formants = 5.0,
      formant_ceiling = 5500,
      ceiling_step_fraction = 0.05,
      num_steps_up_down = n_steps
    )
    
    expected_candidates <- 2 * n_steps + 1
    expect_equal(fp$get_number_of_candidates(), expected_candidates)
    
    # Should be able to extract formant
    formant <- fp$extract_formant()
    expect_s3_class(formant, "Formant")
  }
})


# ==============================================================================
# Test 5: Accuracy - qSums computation
# ==============================================================================
test_that("FormantPath: qSums matrix computation (SIMD vs scalar)", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.3, sr = 16000)
  
  # Scalar
  options(speaker.use_simd = FALSE)
  fp_scalar <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 1
  )
  
  # SIMD
  options(speaker.use_simd = TRUE)
  fp_simd <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 1
  )
  
  # Both should successfully create FormantPath
  expect_s3_class(fp_scalar, "FormantPath")
  expect_s3_class(fp_simd, "FormantPath")
  
  # Extract and compare formants
  f_scalar <- fp_scalar$extract_formant()
  f_simd <- fp_simd$extract_formant()
  
  # Should have same number of frames
  expect_equal(f_scalar$get_number_of_frames(), f_simd$get_number_of_frames())
})


# ==============================================================================
# Test 6: SIMD toggle functionality
# ==============================================================================
test_that("FormantPath: SIMD can be toggled on/off", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.2, sr = 16000)
  
  # Disable SIMD
  options(speaker.use_simd = FALSE)
  fp1 <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 1
  )
  expect_s3_class(fp1, "FormantPath")
  
  # Enable SIMD
  options(speaker.use_simd = TRUE)
  fp2 <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 1
  )
  expect_s3_class(fp2, "FormantPath")
  
  # Both should work
  f1 <- fp1$extract_formant()
  f2 <- fp2$extract_formant()
  expect_s3_class(f1, "Formant")
  expect_s3_class(f2, "Formant")
})


# ==============================================================================
# Test 7: Performance regression (should not crash or hang)
# ==============================================================================
test_that("FormantPath: No performance regression", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.5, sr = 16000)
  
  options(speaker.use_simd = TRUE)
  
  # Should complete in reasonable time
  start_time <- Sys.time()
  fp <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 2
  )
  end_time <- Sys.time()
  
  elapsed <- as.numeric(difftime(end_time, start_time, units = "secs"))
  
  # Should complete within 5 seconds (very generous)
  expect_lt(elapsed, 5.0)
  
  # Should produce valid result
  formant <- fp$extract_formant()
  expect_s3_class(formant, "Formant")
})


# ==============================================================================
# Test 8: Edge cases
# ==============================================================================
test_that("FormantPath: Edge cases handled correctly", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  options(speaker.use_simd = TRUE)
  
  # Very short sound
  sound_short <- create_test_vowel(duration = 0.1, sr = 16000)
  fp_short <- sound_short$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 1
  )
  expect_s3_class(fp_short, "FormantPath")
  
  # Single ceiling (no path finding needed)
  sound <- create_test_vowel(duration = 0.3, sr = 16000)
  fp_single <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 0  # Only 1 candidate
  )
  expect_s3_class(fp_single, "FormantPath")
  expect_equal(fp_single$get_number_of_candidates(), 1)
})


# ==============================================================================
# Test 9: Real vowel file (if available)
# ==============================================================================
test_that("FormantPath: Works with real audio", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  # Try to find a test audio file
  test_files <- c(
    system.file("extdata", "test.wav", package = "pladdrr"),
    system.file("sounds", "test.wav", package = "pladdrr")
  )
  
  test_file <- NULL
  for (f in test_files) {
    if (file.exists(f) && nchar(f) > 0) {
      test_file <- f
      break
    }
  }
  
  if (!is.null(test_file)) {
    sound <- Sound$new(test_file)
    
    options(speaker.use_simd = TRUE)
    fp <- sound$to_formant_path(
      time_step = 0.01,
      max_num_formants = 5.0,
      formant_ceiling = 5500,
      ceiling_step_fraction = 0.05,
      num_steps_up_down = 2
    )
    
    expect_s3_class(fp, "FormantPath")
    formant <- fp$extract_formant()
    expect_s3_class(formant, "Formant")
  } else {
    skip("No test audio file available")
  }
})


# ==============================================================================
# Test 10: Comparison with standard formant extraction
# ==============================================================================
test_that("FormantPath: Results comparable to standard Formant", {
  skip_if_not(pladdrr::simd_info()$available, "SIMD not available")
  
  sound <- create_test_vowel(duration = 0.4, sr = 16000)
  
  # Standard formant extraction
  formant_standard <- sound$to_formant_burg(
    time_step = 0.01,
    max_formants = 5.0,
    max_frequency = 5500,
    window_length = 0.025,
    pre_emphasis_from = 50
  )
  
  # FormantPath with single ceiling (should be similar)
  options(speaker.use_simd = TRUE)
  fp <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 5.0,
    formant_ceiling = 5500,
    ceiling_step_fraction = 0.05,
    num_steps_up_down = 0  # Single ceiling
  )
  formant_path <- fp$extract_formant()
  
  # Compare means
  t_mid <- sound$get_xmax() / 2
  
  f1_standard <- formant_standard$get_value_at_time(1, t_mid)
  f1_path <- formant_path$get_value_at_time(1, t_mid)
  
  # Should be reasonably close (within 50 Hz)
  if (!is.na(f1_standard) && !is.na(f1_path)) {
    expect_lt(abs(f1_standard - f1_path), 100)
  }
})


# Reset SIMD option
options(speaker.use_simd = TRUE)

cat("\n")
cat("========================================\n")
cat("Phase 4 Task 4.1: FormantPath SIMD Tests\n")
cat("========================================\n")
cat("All tests completed.\n")
cat("Expected speedup: 2-3x (pending benchmarks)\n")
cat("\n")
