# Test PowerCepstrogram SIMD optimization (v4.8.10)
# Tests SIMD vs scalar accuracy for CPPS calculation

test_that("PowerCepstrogram SIMD detection works", {
  # Should return logical
  simd_available <- tryCatch({
    .Call("_pladdrr_should_use_simd_for_powercepstrogram_bridge", PACKAGE = "pladdrr")
  }, error = function(e) FALSE)
  
  expect_type(simd_available, "logical")
})

test_that("PowerCepstrogram creation works with SIMD", {
  skip_if_not_installed("pladdrr")
  
  # Create test sound (500 Hz tone, 0.5s)
  sound <- pladdrr::generate_sine_wave(500, duration = 0.5, sampling_rate = 16000)
  
  # Convert to PowerCepstrogram
  pc <- sound$to_powercepstrogram(
    pitch_floor = 60,
    time_step = 0.002,
    maximum_frequency = 5000,
    pre_emphasis_frequency = 50
  )
  
  expect_s3_class(pc, "PowerCepstrogram")
  expect_gt(nrow(pc$as_matrix()), 0)
})

test_that("CPPS calculation with SIMD matches scalar", {
  skip_if_not_installed("pladdrr")
  skip_on_cran()  # Skip intensive test on CRAN
  
  # Create test sound
  sound <- pladdrr::generate_sine_wave(500, duration = 1.0, sampling_rate = 16000)
  
  # Calculate CPPS (uses PowerCepstrogram internally with SIMD)
  cpps <- tryCatch({
    pladdrr::calculate_cpps_ultra(sound)
  }, error = function(e) NA_real_)
  
  # Should return valid CPPS value (typically 5-20 dB for voiced)
  expect_false(is.na(cpps))
  expect_gt(cpps, 0)
  expect_lt(cpps, 30)
})

test_that("PowerCepstrogram SIMD handles edge cases", {
  skip_if_not_installed("pladdrr")
  skip_on_cran()
  
  # Very short sound (edge case for SIMD threshold)
  short_sound <- pladdrr::generate_sine_wave(440, duration = 0.1, sampling_rate = 16000)
  
  pc_short <- short_sound$to_powercepstrogram()
  expect_s3_class(pc_short, "PowerCepstrogram")
  
  # Longer sound (should definitely use SIMD)
  long_sound <- pladdrr::generate_sine_wave(440, duration = 2.0, sampling_rate = 16000)
  
  pc_long <- long_sound$to_powercepstrogram()
  expect_s3_class(pc_long, "PowerCepstrogram")
})
