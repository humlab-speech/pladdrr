# Tests for Zero-Copy Data Access
# Part of Phase 3 Performance Enhancements (v2.0.7)

test_that("sound_values_zerocopy returns correct data", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  # Get values using both methods
  regular <- sound$get_values(1)
  zerocopy <- get_sound_values_zerocopy(sound, channel = 1)
  
  # Values should be identical
  expect_equal(zerocopy, regular, tolerance = 1e-10)
  expect_equal(length(zerocopy), sound$get_number_of_samples())
})


test_that("zerocopy vector has correct attributes", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  zerocopy <- get_sound_values_zerocopy(sound, channel = 1)
  
  # Check attributes
  expect_true(inherits(zerocopy, "zerocopy_vector"))
  expect_true(attr(zerocopy, "readonly"))
  expect_true(is_zerocopy_vector(zerocopy))
  
  # Regular vector should not be zerocopy
  regular <- sound$get_values(1)
  expect_false(is_zerocopy_vector(regular))
})


test_that("zerocopy validates channel number", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  # Invalid channel
  expect_error(get_sound_values_zerocopy(sound, channel = 0))
  expect_error(get_sound_values_zerocopy(sound, channel = 999))
})


test_that("zerocopy validates Sound object", {
  expect_error(get_sound_values_zerocopy("not a sound", channel = 1))
  expect_error(get_sound_values_zerocopy(NULL, channel = 1))
})


test_that("sound_times_fast returns correct times", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  times_fast <- get_sound_times_fast(sound)
  times_regular <- sound$get_sample_times()
  
  expect_equal(times_fast, times_regular, tolerance = 1e-10)
  expect_equal(length(times_fast), sound$get_number_of_samples())
})


test_that("zerocopy data remains valid while Sound exists", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  zerocopy <- get_sound_values_zerocopy(sound, channel = 1)
  
  # Compute statistics on zerocopy view
  rms1 <- sqrt(mean(zerocopy^2))
  peak1 <- max(abs(zerocopy))
  
  # Sound still exists, data should be valid
  expect_true(is.numeric(rms1))
  expect_true(is.numeric(peak1))
  expect_true(rms1 > 0)
  expect_true(peak1 > 0)
  
  # Recompute - should get same results
  rms2 <- sqrt(mean(zerocopy^2))
  peak2 <- max(abs(zerocopy))
  
  expect_equal(rms1, rms2)
  expect_equal(peak1, peak2)
})


test_that("zerocopy is read-only operation", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  zerocopy <- get_sound_values_zerocopy(sound, channel = 1)
  original_value <- zerocopy[100]
  
  # WARNING: This test documents expected behavior
  # Modifying zerocopy data is UNDEFINED BEHAVIOR and may:
  # 1. Corrupt Praat's internal data
  # 2. Crash R
  # 3. Cause segfaults
  #
  # We DO NOT test modification because it's dangerous
  # Instead, we verify the warning attribute exists
  
  expect_true(attr(zerocopy, "readonly"))
  expect_match(attr(zerocopy, "warning"), "READ-ONLY")
})


test_that("sound_as_matrix_zerocopy works for mono", {
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  # Regular matrix
  mat_regular <- sound$as_matrix()
  
  # Zerocopy matrix (only works for mono)
  if (sound$get_number_of_channels() == 1) {
    mat_zerocopy <- sound_as_matrix_zerocopy(sound, zerocopy = TRUE)
    expect_equal(mat_zerocopy, mat_regular, tolerance = 1e-10)
  }
})


test_that("zerocopy performance is faster", {
  skip_if_not_installed("microbenchmark")
  
  sound_file <- system.file("signalfiles/helloworld.wav", package = "pladdrr")
  sound <- Sound(sound_file)
  
  # Benchmark
  library(microbenchmark)
  result <- microbenchmark(
    regular = sound$get_values(1),
    zerocopy = get_sound_values_zerocopy(sound, 1),
    times = 50
  )
  
  # Zerocopy should be faster
  median_regular <- median(result$time[result$expr == "regular"])
  median_zerocopy <- median(result$time[result$expr == "zerocopy"])
  
  speedup <- median_regular / median_zerocopy
  
  # Expect at least 1.5x speedup (conservative, usually 3-10x)
  expect_gt(speedup, 1.5)
  
  message(sprintf("Zerocopy speedup: %.1fx", speedup))
})
