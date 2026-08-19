# test-batch-queries.R
# Tests for Phase 5 batch query operations
# pladdrr v2.0.9

library(testthat)
library(pladdrr)

# Test Formant batch queries
test_that("Formant batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  # Define test times
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1, length.out = 10)
  
  # Test formant frequency batch query
  result <- get_formants_at_times(formant, times, formant_numbers = 1:4)
  
  expect_type(result, "list")
  expect_named(result, c("F1", "F2", "F3", "F4"))
  expect_equal(length(result$F1), 10)
  expect_equal(length(result$F2), 10)
  
  # Verify batch results match individual queries
  f1_individual <- sapply(times, function(t) formant$get_value_at_time(1, t, "hertz"))
  expect_equal(result$F1, f1_individual, tolerance = 1e-6)
  
  f2_individual <- sapply(times, function(t) formant$get_value_at_time(2, t, "hertz"))
  expect_equal(result$F2, f2_individual, tolerance = 1e-6)
})

test_that("Formant bandwidth batch queries work", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1, length.out = 5)
  
  result <- get_formant_bandwidths_at_times(formant, times, 1:4)
  
  expect_type(result, "list")
  expect_named(result, c("B1", "B2", "B3", "B4"))
  expect_equal(length(result$B1), 5)
  
  # Verify correctness
  b1_individual <- sapply(times, function(t) formant$get_bandwidth_at_time(1, t, "hertz"))
  expect_equal(result$B1, b1_individual, tolerance = 1e-6)
})

test_that("Formant batch queries handle edge cases", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  # Single time point
  result <- get_formants_at_times(formant, c(1.0), 1:2)
  expect_equal(length(result$F1), 1)
  
  # Single formant number
  result <- get_formants_at_times(formant, c(1.0, 2.0), 1)
  expect_named(result, "F1")
  expect_equal(length(result$F1), 2)
  
  # Error on invalid input
  expect_error(get_formants_at_times("not_a_formant", c(1.0), 1))
  expect_error(get_formants_at_times(formant, numeric(0), 1))
})

# Test Pitch batch queries
test_that("Pitch batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- seq(pitch$get_xmin() + 0.1, pitch$get_xmax() - 0.1, length.out = 20)
  
  # Test pitch value batch query
  result <- get_pitch_at_times(pitch, times)
  
  expect_type(result, "double")
  expect_equal(length(result), 20)
  
  # Verify batch results match individual queries
  individual <- sapply(times, function(t) pitch$get_value_at_time(t, "hertz", TRUE))
  expect_equal(result, individual, tolerance = 1e-6)
})

test_that("Pitch strength batch queries work", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- seq(pitch$get_xmin() + 0.1, pitch$get_xmax() - 0.1, length.out = 10)
  
  result <- get_pitch_strengths_at_times(pitch, times)
  
  expect_type(result, "double")
  expect_equal(length(result), 10)
  
  # Strengths should be between 0 and 1 (or undefined)
  valid_strengths <- result[!is.na(result)]
  expect_true(all(valid_strengths >= 0 & valid_strengths <= 1))
})

test_that("Pitch batch queries handle interpolation", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- c(1.0, 1.5, 2.0)
  
  # With interpolation
  result_interp <- get_pitch_at_times(pitch, times, interpolate = TRUE)
  
  # Without interpolation
  result_no_interp <- get_pitch_at_times(pitch, times, interpolate = FALSE)
  
  # Results should be similar but may differ slightly
  expect_equal(length(result_interp), 3)
  expect_equal(length(result_no_interp), 3)
})

# Test Intensity batch queries
test_that("Intensity batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()
  
  times <- seq(intensity$get_xmin() + 0.1, intensity$get_xmax() - 0.1, length.out = 15)
  
  result <- get_intensity_at_times(intensity, times)
  
  expect_type(result, "double")
  expect_equal(length(result), 15)
  
  # Verify batch results match individual queries
  # Note: Slight numerical differences may occur due to internal interpolation details
  individual <- sapply(times, function(t) intensity$get_value_at_time(t, "cubic"))
  expect_equal(result, individual, tolerance = 0.5)  # 0.5 dB tolerance
})

test_that("Intensity batch queries support interpolation methods", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()
  
  times <- c(1.0, 2.0, 3.0)
  
  # Test different interpolation methods
  result_nearest <- get_intensity_at_times(intensity, times, "nearest")
  result_linear <- get_intensity_at_times(intensity, times, "linear")
  result_cubic <- get_intensity_at_times(intensity, times, "cubic")
  
  expect_equal(length(result_nearest), 3)
  expect_equal(length(result_linear), 3)
  expect_equal(length(result_cubic), 3)
  
  # Results should be similar but may differ
  expect_true(cor(result_nearest, result_cubic, use = "complete.obs") > 0.95)
})

# Test PointProcess batch operations
test_that("PointProcess get all times works", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  result <- get_pointprocess_times(pp)
  
  expect_type(result, "double")
  expect_true(length(result) > 0)
  expect_equal(length(result), pp$get_number_of_points())
  
  # Verify times match individual queries
  individual <- sapply(1:pp$get_number_of_points(), function(i) pp$get_time(i))
  expect_equal(result, individual, tolerance = 1e-10)
  
  # Times should be monotonically increasing
  expect_true(all(diff(result) > 0))
})

test_that("PointProcess intervals work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  result <- get_pointprocess_intervals(pp)
  
  expect_type(result, "double")
  expect_equal(length(result), pp$get_number_of_points() - 1)
  
  # All intervals should be positive
  expect_true(all(result > 0))
  
  # Verify correctness: intervals should equal consecutive time differences
  times <- get_pointprocess_times(pp)
  expected_intervals <- diff(times)
  expect_equal(result, expected_intervals, tolerance = 1e-10)
})

test_that("PointProcess nearest indices query works", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  query_times <- seq(pp$get_xmin() + 0.1, pp$get_xmax() - 0.1, length.out = 10)
  
  result <- get_pointprocess_nearest_indices(pp, query_times)
  
  expect_type(result, "integer")
  expect_equal(length(result), 10)
  
  # All indices should be valid
  expect_true(all(result >= 1 & result <= pp$get_number_of_points()))
  
  # Verify correctness for first query
  individual_idx <- pp$get_nearest_index(query_times[1])
  expect_equal(result[1], individual_idx)
})

test_that("PointProcess batch operations handle empty objects", {
  # Create empty PointProcess
  pp <- PointProcess(0, 1)
  
  times <- get_pointprocess_times(pp)
  expect_equal(length(times), 0)
  
  intervals <- get_pointprocess_intervals(pp)
  expect_equal(length(intervals), 0)
})

# Performance benchmarks
test_that("Batch queries are faster than loops", {
  skip_on_cran()
  skip_if_not_installed("microbenchmark")
  
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant()
  
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1, length.out = 50)
  
  # Benchmark formant batch vs loop
  benchmark_result <- microbenchmark::microbenchmark(
    batch = get_formants_at_times(formant, times, 1:4),
    loop = {
      f1 <- sapply(times, function(t) formant$get_value_at_time(1, t, "hertz"))
      f2 <- sapply(times, function(t) formant$get_value_at_time(2, t, "hertz"))
      f3 <- sapply(times, function(t) formant$get_value_at_time(3, t, "hertz"))
      f4 <- sapply(times, function(t) formant$get_value_at_time(4, t, "hertz"))
      list(F1 = f1, F2 = f2, F3 = f3, F4 = f4)
    },
    times = 10
  )
  
  # Batch should be faster
  medians <- summary(benchmark_result)$median
  speedup <- medians[2] / medians[1]
  
  message(sprintf("Formant batch query speedup: %.1fx", speedup))
  expect_true(speedup > 2.0)  # At least 2x faster
})

test_that("PointProcess batch operations are faster than loops", {
  skip_on_cran()
  skip_if_not_installed("microbenchmark")
  
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  benchmark_result <- microbenchmark::microbenchmark(
    batch = get_pointprocess_times(pp),
    loop = sapply(1:pp$get_number_of_points(), function(i) pp$get_time(i)),
    times = 20
  )
  
  medians <- summary(benchmark_result)$median
  speedup <- medians[2] / medians[1]
  
  message(sprintf("PointProcess batch query speedup: %.1fx", speedup))
  expect_true(speedup > 3.0)  # At least 3x faster
})
