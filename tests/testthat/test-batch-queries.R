# test-batch-queries.R
# Tests for Phase 5 batch query operations
# pladdrr v2.0.9

library(testthat)
library(pladdrr)

# Test Formant batch queries
test_that("Formant batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  # Define test times
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1,
    length.out = 10)
  
  # Test formant frequency batch query
  result <- get_formants_at_times(formant, times, formant_numbers = 1:4)
  
  expect_type(result, "list")
  expect_named(result, c("F1", "F2", "F3", "F4"))
  expect_length(result$F1, 10)
  expect_length(result$F2, 10)
  
  # Verify batch results match individual queries
  f1_individual <- vapply(times,
    function(t) formant$get_value_at_time(1, t, "hertz"), numeric(1))
  expect_equal(result$F1, f1_individual, tolerance = 1e-6)
  
  f2_individual <- vapply(times,
    function(t) formant$get_value_at_time(2, t, "hertz"), numeric(1))
  expect_equal(result$F2, f2_individual, tolerance = 1e-6)
})

test_that("Formant bandwidth batch queries work", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1,
    length.out = 5)
  
  result <- get_formant_bandwidths_at_times(formant, times, 1:4)
  
  expect_type(result, "list")
  expect_named(result, c("B1", "B2", "B3", "B4"))
  expect_length(result$B1, 5)
  
  # Verify correctness
  b1_individual <- vapply(times,
    function(t) formant$get_bandwidth_at_time(1, t, "hertz"), numeric(1))
  expect_equal(result$B1, b1_individual, tolerance = 1e-6)
})

test_that("Formant batch queries handle edge cases", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  
  # Single time point
  result <- get_formants_at_times(formant, 1.0, 1:2)
  expect_length(result$F1, 1)
  
  # Single formant number
  result <- get_formants_at_times(formant, c(1.0, 2.0), 1)
  expect_named(result, "F1")
  expect_length(result$F1, 2)
  
  # Error on invalid input
  expect_error(get_formants_at_times("not_a_formant", 1.0, 1))
  expect_error(get_formants_at_times(formant, numeric(0), 1))
})

# Test Pitch batch queries
test_that("Pitch batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- seq(pitch$get_xmin() + 0.1, pitch$get_xmax() - 0.1, length.out = 20)
  
  # Test pitch value batch query
  result <- get_pitch_at_times(pitch, times)
  
  expect_type(result, "double")
  expect_length(result, 20)
  
  # Verify batch results match individual queries
  individual <- vapply(times,
    function(t) pitch$get_value_at_time(t, "hertz", TRUE), numeric(1))
  expect_equal(result, individual, tolerance = 1e-6)
})

test_that("Pitch strength batch queries work", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- seq(pitch$get_xmin() + 0.1, pitch$get_xmax() - 0.1, length.out = 10)
  
  result <- get_pitch_strengths_at_times(pitch, times)
  
  expect_type(result, "double")
  expect_length(result, 10)
  
  # Strengths should be between 0 and 1 (or undefined)
  valid_strengths <- result[!is.na(result)]
  expect_true(all(valid_strengths >= 0 & valid_strengths <= 1))
})

test_that("Pitch batch queries handle interpolation", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  
  times <- c(1.0, 1.5, 2.0)
  
  # With interpolation
  result_interp <- get_pitch_at_times(pitch, times, interpolate = TRUE)
  
  # Without interpolation
  result_no_interp <- get_pitch_at_times(pitch, times, interpolate = FALSE)
  
  # Results should be similar but may differ slightly
  expect_length(result_interp, 3)
  expect_length(result_no_interp, 3)
})

# Test Intensity batch queries
test_that("Intensity batch queries work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()
  
  times <- seq(intensity$get_xmin() + 0.1, intensity$get_xmax() - 0.1,
    length.out = 15)
  
  result <- get_intensity_at_times(intensity, times)
  
  expect_type(result, "double")
  expect_length(result, 15)
  
  # Verify batch results match individual queries
  # Note: Slight numerical differences may occur due to internal interpolation
  #  details
  individual <- vapply(times,
    function(t) intensity$get_value_at_time(t, "cubic"), numeric(1))
  expect_equal(result, individual, tolerance = 0.5)  # 0.5 dB tolerance
})

test_that("Intensity batch queries support interpolation methods", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()
  
  times <- c(1.0, 2.0, 3.0)
  
  # Test different interpolation methods
  result_nearest <- get_intensity_at_times(intensity, times, "nearest")
  result_linear <- get_intensity_at_times(intensity, times, "linear")
  result_cubic <- get_intensity_at_times(intensity, times, "cubic")
  
  expect_length(result_nearest, 3)
  expect_length(result_linear, 3)
  expect_length(result_cubic, 3)
  
  # Results should be similar but may differ
  expect_gt(cor(result_nearest, result_cubic, use = "complete.obs"), 0.95)
})

# Test PointProcess batch operations
test_that("PointProcess get all times works", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  result <- get_pointprocess_times(pp)
  
  expect_type(result, "double")
  expect_gt(length(result), 0)
  expect_length(result, pp$get_number_of_points())
  
  # Verify times match individual queries
  individual <- vapply(1:pp$get_number_of_points(), pp$get_time, numeric(1))
  expect_equal(result, individual, tolerance = 1e-10)
  
  # Times should be monotonically increasing
  expect_true(all(diff(result) > 0))
})

test_that("PointProcess intervals work correctly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  result <- get_pointprocess_intervals(pp)
  
  expect_type(result, "double")
  expect_length(result, pp$get_number_of_points() - 1)
  
  # All intervals should be positive
  expect_true(all(result > 0))
  
  # Verify correctness: intervals should equal consecutive time differences
  times <- get_pointprocess_times(pp)
  expected_intervals <- diff(times)
  expect_equal(result, expected_intervals, tolerance = 1e-10)
})

test_that("PointProcess nearest indices query works", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  query_times <- seq(pp$get_xmin() + 0.1, pp$get_xmax() - 0.1, length.out = 10)
  
  result <- get_pointprocess_nearest_indices(pp, query_times)
  
  expect_type(result, "integer")
  expect_length(result, 10)
  
  # All indices should be valid
  expect_true(all(result >= 1 & result <= pp$get_number_of_points()))
  
  # Verify correctness for first query
  individual_idx <- pp$get_nearest_index(query_times[1])
  expect_equal(result[1], individual_idx, tolerance = sqrt(.Machine$double.eps))
})

test_that("PointProcess batch operations handle empty objects", {
  # Create empty PointProcess
  pp <- PointProcess(0, 1)

  times <- get_pointprocess_times(pp)
  expect_length(times, 0)

  intervals <- get_pointprocess_intervals(pp)
  expect_length(intervals, 0)
})

test_that(
  "formant/bandwidth/pitch-strength batch queries return NA for non-finite query times", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()
  pitch <- sound$to_pitch_cc()

  mid_time <- (formant$get_xmin() + formant$get_xmax()) / 2
  times_with_gaps <- c(mid_time, NA_real_, Inf, -Inf, NaN)

  expect_warning(
    formants <- get_formants_at_times(formant, times_with_gaps, 1:2),
    "undefined"
  )
  expect_length(formants$F1, 5)
  expect_true(all(is.na(formants$F1[2:5])))
  expect_false(is.na(formants$F1[1]))

  # Unlike get_formants_at_times(), the bandwidth batch C++ export
  # (formant_get_multiple_bandwidths_at_times) does not pre-filter
  # non-finite times per-value; a non-finite time reaches
  # Formant_getBandwidthAtTime()/Sampled_getValueAtX() directly, which
  # raises a MelderError that the wrapper turns into a hard R error
  # (see src/batch_queries.cpp's catch block around "Failed to query
  # formant bandwidths"). Verified by direct run, not assumed.
  expect_error(
    get_formant_bandwidths_at_times(formant, times_with_gaps, 1:2),
    "Failed to query formant bandwidths"
  )

  pitch_times <- c((pitch$get_xmin() + pitch$get_xmax()) / 2, NA_real_, Inf)
  expect_warning(
    strengths <- get_pitch_strengths_at_times(pitch, pitch_times),
    "undefined"
  )
  expect_length(strengths, 3)
  expect_true(all(is.na(strengths[2:3])))
})

test_that(
  "internal formant batch functions reject an out-of-range formant index directly", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant_burg()

  # get_formants_at_times()/get_formant_bandwidths_at_times() only check that
  # formant_numbers is non-empty numeric; they do not check that each entry
  # is >= 1, so a 0/negative formant number reaches the C++ bounds check.
  expect_error(
    pladdrr:::formant_get_multiple_formants_at_times(formant$.xptr, 0.1, 0L),
    "formant index"
  )
  # formant_get_multiple_bandwidths_at_times() has no equivalent >= 1 bounds
  # check (verified by reading src/batch_queries.cpp and running directly):
  # an out-of-range formant index reaches Formant_getBandwidthAtTime()/
  # Sampled_getValueAtX() with an invalid column and comes back as NaN
  # rather than throwing. Confirmed non-crashing by direct run.
  bandwidth_oor <- pladdrr:::formant_get_multiple_bandwidths_at_times(
    formant$.xptr, 0.1, -1L)
  expect_true(is.nan(bandwidth_oor[[1]]))

  # Calling the internal C++ export directly (bypassing the R wrapper's
  # non-empty check) exercises the empty-vector guard inside the C++ layer.
  expect_error(
    pladdrr:::formant_get_multiple_formants_at_times(formant$.xptr, 0.1,
      integer(0)),
    "non-empty"
  )
})

test_that(
  "get_pitch_quantiles_batch() computes named quantiles over default and explicit ranges", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()

  # Default from_time = to_time = 0 means "use the whole object range"
  quartiles_default <- get_pitch_quantiles_batch(pitch, c(0.25, 0.5, 0.75))
  expect_length(quartiles_default, 3)
  expect_named(quartiles_default, c("q0.25", "q0.5", "q0.75"))

  # Explicit sub-range skips the "use whole range" branch
  quartiles_range <- get_pitch_quantiles_batch(
    pitch, c(0.25, 0.75),
    from_time = pitch$get_xmin(), to_time = pitch$get_xmax()
  )
  expect_length(quartiles_range, 2)

  # Quartiles should be non-decreasing and within a plausible F0 range
  valid <- quartiles_default[!is.na(quartiles_default)]
  if (length(valid) == 3) {
    expect_lte(valid["q0.25"], valid["q0.5"])
    expect_lte(valid["q0.5"], valid["q0.75"])
  }
})

test_that("internal batch-query C++ exports reject a null external pointer", {
  null_ptr <- methods::new("externalptr")

  expect_error(
    pladdrr:::formant_get_multiple_bandwidths_at_times(null_ptr, 0.1, 1L))
  expect_error(pladdrr:::pitch_get_quantiles_batch(null_ptr, 0.5))
  expect_error(pladdrr:::pointprocess_get_all_times(null_ptr))
  expect_error(pladdrr:::pointprocess_get_intervals(null_ptr))
  expect_error(pladdrr:::pointprocess_get_nearest_indices(null_ptr, 0.1))
  expect_error(
    pladdrr:::pitch_get_statistics_batch(null_ptr, 0, 1, "mean")
  )
  expect_error(pladdrr:::pitch_get_adaptive_range(null_ptr))
  expect_error(
    pladdrr:::intensity_get_statistics_batch(null_ptr, 0, 1, "mean")
  )
  expect_error(pladdrr:::intensity_get_minimum_with_time(null_ptr))

  # get_jitter_shimmer_batch_cpp() validates its two pointers (PointProcess,
  # Sound) independently -- exercise both guards, not just "both null".
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pp <- sound$to_point_process_periodic_cc(75, 600)
  expect_error(
    pladdrr:::get_jitter_shimmer_batch_cpp(null_ptr, sound$.xptr),
    "PointProcess"
  )
  expect_error(
    pladdrr:::get_jitter_shimmer_batch_cpp(pp$.xptr, null_ptr),
    "Sound"
  )
})

test_that(
  "pitch_get_statistics_batch supports median/count_voiced metrics and validates inputs", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()

  # Mismatched from_times/to_times length -> C++ input-validation error
  expect_error(
    pladdrr:::pitch_get_statistics_batch(
      pitch$.xptr, c(0, 0.5), 1.0, "mean", 0L
    ),
    "same length"
  )

  # "q50" (median) and "count_voiced" are supported metrics that the existing
  # performance-enhancement tests never exercise; from=to=0 also exercises the
  # "use whole object range" branch (as opposed to an explicit sub-interval).
  result <- pladdrr:::pitch_get_statistics_batch(
    pitch$.xptr, 0, 0, c("q50", "count_voiced"), 0L
  )
  expect_equal(colnames(result), c("q50", "count_voiced"),
    tolerance = sqrt(.Machine$double.eps))
  expect_identical(nrow(result), 1L)
  expect_gte(result[1, "count_voiced"], 0)

  # Unrecognized metric name -> "Unknown metric" C++ input-validation error
  expect_error(
    pladdrr:::pitch_get_statistics_batch(pitch$.xptr, 0, 0,
      "not_a_real_metric", 0L),
    "Unknown metric"
  )
})

test_that(
  "intensity_get_minimum_with_time() returns a minimum value and time", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()

  # Default from_time = to_time = 0 -> whole-object range branch
  result_default <- pladdrr:::intensity_get_minimum_with_time(intensity$.xptr)
  expect_type(result_default, "list")
  expect_named(result_default, c("value", "time"))
  expect_true(is.numeric(result_default$value))
  expect_gte(result_default$time, intensity$get_xmin())
  expect_lte(result_default$time, intensity$get_xmax())

  # Explicit sub-range skips the "use whole range" branch
  result_range <- pladdrr:::intensity_get_minimum_with_time(
    intensity$.xptr, intensity$get_xmin(), intensity$get_xmax()
  )
  expect_true(is.numeric(result_range$value))
})

test_that(
  "intensity_get_statistics_batch supports q25/q75 metrics and validates inputs", {
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  intensity <- sound$to_intensity()

  expect_error(
    pladdrr:::intensity_get_statistics_batch(
      intensity$.xptr, c(0, 0.5), 1.0, "mean", 0L
    ),
    "same length"
  )

  result <- pladdrr:::intensity_get_statistics_batch(
    intensity$.xptr, 0, 0, c("q25", "q75"), 0L
  )
  expect_equal(colnames(result), c("q25", "q75"),
    tolerance = sqrt(.Machine$double.eps))
  expect_identical(nrow(result), 1L)
  expect_gte(result[1, "q75"], result[1, "q25"])

  # "q50"/"median" (both accepted spellings) are supported but exercised by
  # no existing intensity-statistics test.
  result_median <- pladdrr:::intensity_get_statistics_batch(
    intensity$.xptr, 0, 0, c("q50", "median"), 0L
  )
  expect_equal(as.numeric(result_median[1, "q50"]),
    as.numeric(result_median[1,
      "median"]), tolerance = sqrt(.Machine$double.eps))

  # Unrecognized metric name -> "Unknown metric" C++ input-validation error
  expect_error(
    pladdrr:::intensity_get_statistics_batch(intensity$.xptr, 0, 0,
      "not_a_real_metric", 0L),
    "Unknown metric"
  )
})

# Performance benchmarks
test_that("Batch queries are faster than loops", {
  skip_on_cran()
  skip_if_not_installed("microbenchmark")
  
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  formant <- sound$to_formant()
  
  times <- seq(formant$get_xmin() + 0.1, formant$get_xmax() - 0.1,
    length.out = 50)
  
  # Benchmark formant batch vs loop
  benchmark_result <- microbenchmark::microbenchmark(
    batch = get_formants_at_times(formant, times, 1:4),
    loop = {
      f1 <- vapply(times,
        function(t) formant$get_value_at_time(1, t, "hertz"), numeric(1))
      f2 <- vapply(times,
        function(t) formant$get_value_at_time(2, t, "hertz"), numeric(1))
      f3 <- vapply(times,
        function(t) formant$get_value_at_time(3, t, "hertz"), numeric(1))
      f4 <- vapply(times,
        function(t) formant$get_value_at_time(4, t, "hertz"), numeric(1))
      list(F1 = f1, F2 = f2, F3 = f3, F4 = f4)
    },
    times = 10
  )
  
  # Batch should be faster
  medians <- summary(benchmark_result)$median
  speedup <- medians[2] / medians[1]
  
  message(sprintf("Formant batch query speedup: %.1fx", speedup))
  expect_gt(speedup, 2.0)  # At least 2x faster
})

test_that("PointProcess batch operations are faster than loops", {
  skip_on_cran()
  skip_if_not_installed("microbenchmark")
  
  sound_path <- system.file("signalfiles/DSI/input/fh1.wav",
    package = "pladdrr")
  sound <- Sound(sound_path)
  pitch <- sound$to_pitch_cc()
  pp <- pitch$to_point_process()
  
  benchmark_result <- microbenchmark::microbenchmark(
    batch = get_pointprocess_times(pp),
    loop = vapply(1:pp$get_number_of_points(), pp$get_time, numeric(1)),
    times = 20
  )
  
  medians <- summary(benchmark_result)$median
  speedup <- medians[2] / medians[1]
  
  message(sprintf("PointProcess batch query speedup: %.1fx", speedup))
  expect_gt(speedup, 3.0)  # At least 3x faster
})

test_that("get_jitter_shimmer_batch accepts external-pointer pointprocess", {
  snd <- Sound$create_tone(frequency = 200, duration = 0.2)
  pp <- snd$to_point_process_periodic_cc(75, 300)
  res <- get_jitter_shimmer_batch(pp$.xptr, snd$.xptr)
  expect_type(res, "list")
})

test_that("get_intensity_at_times validates intensity and times", {
  expect_error(get_intensity_at_times("not_an_intensity", c(0.1)),
               "Intensity object")
  snd <- Sound$create_tone(frequency = 200, duration = 0.2)
  inten <- snd$to_intensity()
  expect_error(get_intensity_at_times(inten, numeric(0)),
               "non-empty numeric vector")
})

test_that("get_pitch_quantiles_batch validates pitch and quantiles", {
  snd <- Sound$create_tone(frequency = 200, duration = 0.2)
  expect_error(get_pitch_quantiles_batch(snd, c(0.5)), "pitch must be a Pitch")
  pitch <- snd$to_pitch()
  expect_error(get_pitch_quantiles_batch(pitch, numeric(0)),
               "non-empty numeric vector")
  expect_error(get_pitch_quantiles_batch(pitch, c(-0.1)),
               "between 0 and 1")
})

test_that("get_jitter_shimmer_batch validates pointprocess and sound", {
  snd <- Sound$create_tone(frequency = 200, duration = 0.2)
  expect_error(get_jitter_shimmer_batch("x", snd), "PointProcess")
  pp <- snd$to_point_process_periodic_cc(75, 300)
  expect_error(get_jitter_shimmer_batch(pp, "x"), "Sound object")
})
