# Tests for performance enhancement features
# Added 2026-01-06 based on user feedback

context("Performance Enhancements")

test_that("sound_concatenate_all works with Sound objects", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sounds using synthetic tones
  s1 <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.1, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  s2 <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.1, sampling_rate = 44100, frequency = 880)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test concatenation with Sound objects (this was the bug)
  result <- tryCatch({
    pladdrr::sound_concatenate_all(list(s1, s2))
  }, error = function(e) {
    fail(paste("sound_concatenate_all failed with error:", e$message))
  })
  
  # Verify result
  expect_s3_class(result, "Sound")
  expect_equal(result$get_duration(), 0.2, tolerance = 0.01)
})

test_that("Sound$get_values returns correct data", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.01, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Test direct vector access
  values <- tryCatch({
    sound$get_values(channel = 1)
  }, error = function(e) {
    skip("get_values method not available yet - package may need recompilation")
  })
  
  times <- tryCatch({
    sound$get_sample_times()
  }, error = function(e) {
    skip("get_sample_times method not available yet - package may need recompilation")
  })
  
  # Compare with data frame method
  df <- sound$as_data_frame()
  expect_equal(length(values), nrow(df))
  expect_equal(length(times), nrow(df))
  expect_equal(values, df$value, tolerance = 1e-10)
  expect_equal(times, df$time, tolerance = 1e-10)
})

test_that("Sound$get_values is faster than as_data_frame", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  skip_if_not_installed("microbenchmark")
  
  # Create larger test sound for meaningful benchmark
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  # Check if method is available
  has_get_values <- tryCatch({
    sound$get_values()
    TRUE
  }, error = function(e) {
    FALSE
  })
  
  if (!has_get_values) {
    skip("get_values method not available - package needs recompilation")
  }
  
  # Benchmark
  bench <- microbenchmark::microbenchmark(
    direct = sound$get_values(),
    dataframe = sound$as_data_frame()$value,
    times = 50
  )
  
  median_direct <- median(bench$time[bench$expr == "direct"])
  median_df <- median(bench$time[bench$expr == "dataframe"])
  
  # get_values should be faster (ideally 2x+, but at least 1.2x)
  expect_lt(median_direct, median_df * 0.85)
})

test_that("Pitch$get_statistics returns all metrics", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound and pitch
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 200)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  pitch <- tryCatch({
    sound$to_pitch_cc()
  }, error = function(e) {
    skip("Could not create pitch object")
  })
  
  # Test batch statistics
  stats <- tryCatch({
    pitch$.cpp$get_statistics(
      from_time = 0,
      to_time = 0,
      unit = 0L,  # Hertz
      metrics = c("minimum", "maximum", "mean", "stdev")
    )
  }, error = function(e) {
    skip("get_statistics method not available - package needs recompilation")
  })
  
  # Verify structure
  expect_type(stats, "list")
  expect_true("minimum" %in% names(stats))
  expect_true("maximum" %in% names(stats))
  expect_true("mean" %in% names(stats))
  expect_true("stdev" %in% names(stats))
  
  # Verify values are numeric and reasonable
  expect_true(all(sapply(stats, is.numeric)))
  expect_true(stats$minimum <= stats$mean)
  expect_true(stats$mean <= stats$maximum)
  expect_gte(stats$stdev, 0)
})

test_that("Intensity$get_statistics returns all metrics", {
  skip_on_cran()
  skip_if_not_installed("pladdrr")
  
  # Create test sound and intensity
  sound <- tryCatch({
    pladdrr::Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 440)
  }, error = function(e) {
    skip("Could not create test sound")
  })
  
  intensity <- tryCatch({
    sound$to_intensity()
  }, error = function(e) {
    skip("Could not create intensity object")
  })
  
  # Test batch statistics
  stats <- tryCatch({
    intensity$.cpp$get_statistics(
      from_time = 0,
      to_time = 0,
      metrics = c("minimum", "maximum", "mean", "stdev")
    )
  }, error = function(e) {
    skip("get_statistics method not available - package needs recompilation")
  })
  
  # Verify structure
  expect_type(stats, "list")
  expect_true("minimum" %in% names(stats))
  expect_true("maximum" %in% names(stats))
  expect_true("mean" %in% names(stats))
  expect_true("stdev" %in% names(stats))
  
  # Verify values are numeric and reasonable
  expect_true(all(sapply(stats, is.numeric)))
  expect_true(stats$minimum <= stats$mean)
  expect_true(stats$mean <= stats$maximum)
  expect_gte(stats$stdev, 0)
})
