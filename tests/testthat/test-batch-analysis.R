# Tests for batch analysis functions
# Added 2026-01-06 as part of Phase 2 Performance Enhancements

context("Batch Analysis Functions")

test_that("voice_quality_batch returns correct structure", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 200)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test batch voice quality analysis
  result <- tryCatch({
    pladdrr::voice_quality_batch(sound)
  }, error = function(e) {
    fail(paste("voice_quality_batch failed:", e$message))
  })
  
  # Check structure
  expect_type(result, "list")
  expect_true("pitch" %in% names(result))
  expect_true("intensity" %in% names(result))
  
  # Check pitch statistics
  expect_true("mean" %in% names(result$pitch))
  expect_true("maximum" %in% names(result$pitch))
  expect_true("minimum" %in% names(result$pitch))
  expect_true("stdev" %in% names(result$pitch))
  expect_true("median" %in% names(result$pitch))
  
  # Check intensity statistics
  expect_true("mean" %in% names(result$intensity))
  expect_true("maximum" %in% names(result$intensity))
  expect_true("minimum" %in% names(result$intensity))
  expect_true("stdev" %in% names(result$intensity))
  expect_true("median" %in% names(result$intensity))
  
  # Check values are reasonable for 200 Hz tone
  expect_true(result$pitch$mean > 190 && result$pitch$mean < 210)
  expect_true(result$intensity$mean > 0)
})


test_that("voice_quality_batch matches individual calls", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 220)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Batch approach
  batch_result <- pladdrr::voice_quality_batch(sound)
  
  # Individual approach
  pitch <- sound$to_pitch_cc()
  intensity <- sound$to_intensity()
  
  individual_result <- list(
    pitch = list(
      mean = pitch$get_mean(0, 0, "Hz"),
      maximum = pitch$get_maximum(0, 0, "Hz"),
      minimum = pitch$get_minimum(0, 0, "Hz")
    ),
    intensity = list(
      mean = intensity$get_mean(0, 0),
      maximum = intensity$get_maximum(0, 0),
      minimum = intensity$get_minimum(0, 0)
    )
  )
  
  # Compare results (allow small numerical differences)
  expect_equal(batch_result$pitch$mean, individual_result$pitch$mean, tolerance = 0.01)
  expect_equal(batch_result$pitch$maximum, individual_result$pitch$maximum, tolerance = 0.01)
  expect_equal(batch_result$pitch$minimum, individual_result$pitch$minimum, tolerance = 0.01)
  expect_equal(batch_result$intensity$mean, individual_result$intensity$mean, tolerance = 0.1)
  expect_equal(batch_result$intensity$maximum, individual_result$intensity$maximum, tolerance = 0.1)
  expect_equal(batch_result$intensity$minimum, individual_result$intensity$minimum, tolerance = 0.1)
})


test_that("formant_analysis_batch returns correct structure", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test batch formant analysis
  result <- tryCatch({
    pladdrr::formant_analysis_batch(sound, formant_numbers = c(1L, 2L, 3L))
  }, error = function(e) {
    fail(paste("formant_analysis_batch failed:", e$message))
  })
  
  # Check structure
  expect_type(result, "list")
  expect_true("F1" %in% names(result))
  expect_true("F2" %in% names(result))
  expect_true("F3" %in% names(result))
  
  # Check F1 statistics
  expect_true("mean" %in% names(result$F1))
  expect_true("stdev" %in% names(result$F1))
  expect_true("median" %in% names(result$F1))
  expect_true("minimum" %in% names(result$F1))
  expect_true("maximum" %in% names(result$F1))
  
  # Check values are numeric
  expect_type(result$F1$mean, "double")
  expect_type(result$F2$mean, "double")
  expect_type(result$F3$mean, "double")
})


test_that("formant_analysis_batch matches individual calls", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 300)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Batch approach
  batch_result <- pladdrr::formant_analysis_batch(sound, formant_numbers = c(1L, 2L))
  
  # Individual approach
  formant <- sound$to_formant_burg()
  individual_result <- list(
    F1 = list(
      mean = formant$get_mean(1, 0, 0, "Hz")
    ),
    F2 = list(
      mean = formant$get_mean(2, 0, 0, "Hz")
    )
  )
  
  # Compare results
  expect_equal(batch_result$F1$mean, individual_result$F1$mean, tolerance = 1.0)
  expect_equal(batch_result$F2$mean, individual_result$F2$mean, tolerance = 1.0)
})


test_that("pitch_harmonicity_batch returns correct structure", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 150)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test combined pitch/harmonicity analysis
  result <- tryCatch({
    pladdrr::pitch_harmonicity_batch(sound)
  }, error = function(e) {
    fail(paste("pitch_harmonicity_batch failed:", e$message))
  })
  
  # Check structure
  expect_type(result, "list")
  expect_true("pitch" %in% names(result))
  expect_true("hnr" %in% names(result))
  
  # Check pitch statistics
  expect_true("mean" %in% names(result$pitch))
  expect_true("maximum" %in% names(result$pitch))
  expect_true("minimum" %in% names(result$pitch))
  
  # Check HNR statistics
  expect_true("mean" %in% names(result$hnr))
  expect_true("stdev" %in% names(result$hnr))
  
  # Check pitch value is reasonable for 150 Hz tone
  expect_true(result$pitch$mean > 140 && result$pitch$mean < 160)
})


test_that("batch functions handle invalid input gracefully", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Test with non-Sound object
  expect_error(
    pladdrr::voice_quality_batch("not a sound"),
    "Sound object"
  )
  
  expect_error(
    pladdrr::formant_analysis_batch(list(foo = "bar")),
    "Sound object"
  )
  
  expect_error(
    pladdrr::pitch_harmonicity_batch(NULL),
    "Sound object"
  )
})
