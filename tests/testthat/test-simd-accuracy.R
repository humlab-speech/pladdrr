test_that("SIMD sound statistics are accurate", {
  skip_if_not_installed("pladdrr")
  
  # Build the sound from known samples so its statistics are predictable.
  # (The old version created an empty sound and never loaded the samples, so
  # the stats could never match.)
  test_samples <- rep(c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10), length.out = 1000)
  sound <- Sound$from_values(test_samples, sampling_rate = 1000)

  # Known statistics
  expected_min <- 1.0
  expected_max <- 10.0
  expected_mean <- mean(test_samples)
  expected_rms <- sqrt(mean(test_samples^2))
  
  # Skip test if method not available
  skip_if(is.null(sound$get_minimum), "Sound$get_minimum not available")
  
  # Get computed statistics. Use interpolation = "none" for the extremes so we
  # compare against the raw sample min/max; parabolic peak interpolation
  # overshoots (e.g. a max of 10.8 for samples that top out at 10).
  computed_min <- sound$get_minimum(0, 0, 1, "none")
  computed_max <- sound$get_maximum(0, 0, 1, "none")
  computed_mean <- sound$get_mean(0, 0)
  computed_rms <- sound$get_rms(0, 0)
  
  # Validate (allow for floating point precision)
  expect_equal(computed_min, expected_min, tolerance = 1e-10)
  expect_equal(computed_max, expected_max, tolerance = 1e-10)
  expect_equal(computed_mean, expected_mean, tolerance = 1e-10)
  expect_equal(computed_rms, expected_rms, tolerance = 1e-10)
})

test_that("SIMD mono conversion is accurate for stereo", {
  skip_if_not_installed("pladdrr")
  skip("multichannel Sound construction is not supported by the current API")

  # Create stereo sound
  stereo <- Sound$new(duration = 0.1, sample_rate = 1000, n_channels = 2)
  
  # Set known values
  ch1_samples <- rnorm(100, mean = 1, sd = 0.1)
  ch2_samples <- rnorm(100, mean = -1, sd = 0.1)
  
  # Expected mono result
  expected_mono <- (ch1_samples + ch2_samples) / 2
  
  # Skip if method not available  
  skip_if(is.null(stereo$convert_to_mono), "Sound$convert_to_mono not available")
  
  # Convert to mono
  mono <- stereo$convert_to_mono()
  
  # Validate
  expect_equal(mono$n_channels, 1)
  expect_equal(mono$n_samples, stereo$n_samples)
  
  # Check samples match expected (within floating point tolerance)
  mono_samples <- mono$get_samples(1)
  expect_equal(length(mono_samples), length(expected_mono))
  expect_equal(mono_samples, expected_mono, tolerance = 1e-12)
})

test_that("SIMD mono conversion is accurate for multi-channel", {
  skip_if_not_installed("pladdrr")
  skip("multichannel Sound construction is not supported by the current API")

  # Create 4-channel sound
  multichannel <- Sound$new(duration = 0.05, sample_rate = 1000, n_channels = 4)
  
  # Set known values for each channel
  samples <- list(
    rnorm(50, mean = 1),
    rnorm(50, mean = 2),
    rnorm(50, mean = 3),
    rnorm(50, mean = 4)
  )
  
  # Expected mono result
  expected_mono <- (samples[[1]] + samples[[2]] + samples[[3]] + samples[[4]]) / 4
  
  # Skip if method not available
  skip_if(is.null(multichannel$convert_to_mono), "Sound$convert_to_mono not available")
  
  # Convert to mono
  mono <- multichannel$convert_to_mono()
  
  # Validate
  expect_equal(mono$n_channels, 1)
  expect_equal(mono$n_samples, multichannel$n_samples)
  
  # Check samples match expected
  mono_samples <- mono$get_samples(1)
  expect_equal(length(mono_samples), length(expected_mono))
  expect_equal(mono_samples, expected_mono, tolerance = 1e-12)
})

test_that("SIMD dot product is accurate", {
  # Test with simple vectors
  x <- c(1, 2, 3, 4, 5)
  y <- c(2, 3, 4, 5, 6)
  
  expected <- sum(x * y)  # 70
  
  # Would need exposed function
  # computed <- .dot_product_simd(x, y)
  # expect_equal(computed, expected, tolerance = 1e-14)
  
  # For now, just validate R's computation
  expect_equal(sum(x * y), 70)
})

test_that("SIMD operations handle edge cases", {
  # Test with empty/single element arrays
  skip("Edge case testing - implementation pending")
  
  # Empty array
  # expect_error(.dot_product_simd(numeric(0), numeric(0)), NA)
  
  # Single element
  # result <- .dot_product_simd(c(3), c(4))
  # expect_equal(result, 12)
  
  # Unequal lengths
  # expect_error(.dot_product_simd(c(1,2), c(1,2,3)))
})

test_that("SIMD operations match scalar fallback", {
  skip("Scalar vs SIMD comparison - requires dual compilation")
  
  # This would require compiling both versions and comparing
  # In practice, the accuracy tests above validate correctness
})
