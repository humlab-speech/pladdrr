# Tests for Fast Data Access (renamed from zerocopy)

test_that("sound_values_fast returns correct data", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  # Get values using both methods
  regular <- sound$get_values(1)
  fast <- get_sound_values_fast(sound, channel = 1)

  # Values should be identical (ignoring class attributes)
  expect_equal(as.numeric(fast), as.numeric(regular), tolerance = 1e-10)
  expect_length(fast, sound$get_number_of_samples())
})


test_that("fast_vector has correct attributes", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  fast <- get_sound_values_fast(sound, channel = 1)

  # Check attributes
  expect_s3_class(fast, "fast_vector")
  expect_true(attr(fast, "readonly"))
  expect_true(is_fast_vector(fast))

  # Regular vector should not be fast_vector
  regular <- sound$get_values(1)
  expect_false(is_fast_vector(regular))
})


test_that("fast access validates channel number", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  # Invalid channel
  expect_error(get_sound_values_fast(sound, channel = 0))
  expect_error(get_sound_values_fast(sound, channel = 999))
})


test_that("fast access validates Sound object", {
  expect_error(get_sound_values_fast("not a sound", channel = 1))
  expect_error(get_sound_values_fast(NULL, channel = 1))
})


test_that("sound_times_fast returns correct times", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  times_fast <- get_sound_times_fast(sound)
  times_regular <- sound$get_sample_times()

  expect_equal(times_fast, times_regular, tolerance = 1e-10)
  expect_length(times_fast, sound$get_number_of_samples())
})


test_that("fast data remains valid while Sound exists", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  fast <- get_sound_values_fast(sound, channel = 1)

  # Compute statistics
  rms1 <- sqrt(mean(fast^2))
  peak1 <- max(abs(fast))

  # Sound still exists, data should be valid
  expect_true(is.numeric(rms1))
  expect_true(is.numeric(peak1))
  expect_gt(rms1, 0)
  expect_gt(peak1, 0)

  # Recompute - should get same results
  rms2 <- sqrt(mean(fast^2))
  peak2 <- max(abs(fast))

  expect_equal(rms1, rms2)
  expect_equal(peak1, peak2)
})


test_that("sound_as_matrix_fast works for mono", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  # Regular matrix
  mat_regular <- sound$as_matrix()

  # Fast matrix (samples x channels) vs regular (channels x samples)
  mat_fast <- sound_as_matrix_fast(sound)
  expect_equal(t(mat_fast), mat_regular, tolerance = 1e-10)
})


test_that("deprecated aliases still work with warning", {
  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  # get_sound_values_zerocopy -> get_sound_values_fast
  expect_warning(
    vals <- get_sound_values_zerocopy(sound, channel = 1),
    "deprecated"
  )
  expect_length(vals, sound$get_number_of_samples())

  # sound_as_matrix_zerocopy -> sound_as_matrix_fast
  expect_warning(
    mat <- sound_as_matrix_zerocopy(sound),
    "deprecated"
  )
  expect_true(is.matrix(mat))

  # is_zerocopy_vector -> is_fast_vector
  fast_vec <- get_sound_values_fast(sound, 1)
  expect_warning(
    result <- is_zerocopy_vector(fast_vec),
    "deprecated"
  )
  expect_true(result)
})


test_that("fast access performance is faster than regular", {
  skip_if_not_installed("microbenchmark")

  sound_file <- system.file("extdata", "test.wav", package = "pladdrr")
  sound <- Sound(sound_file)

  # Benchmark
  library(microbenchmark)
  result <- microbenchmark(
    regular = sound$get_values(1),
    fast = get_sound_values_fast(sound, 1),
    times = 50
  )

  # Fast should be faster
  median_regular <- median(result$time[result$expr == "regular"])
  median_fast <- median(result$time[result$expr == "fast"])

  speedup <- median_regular / median_fast

  # Expect at least 1.5x speedup (conservative, usually 2-5x)
  expect_gt(speedup, 1.5)

  message(sprintf("Fast access speedup: %.1fx", speedup))
})
