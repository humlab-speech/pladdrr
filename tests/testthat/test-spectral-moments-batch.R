# test-spectral-moments-batch.R
# Regression tests for PERF-1: get_spectral_moments_batch()

test_that("get_spectral_moments_batch() returns correct shape", {
  skip_on_cran()

  sound <- Sound$create_tone(frequency = 440, duration = 0.5)
  spg   <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000, time_step = 0.002, frequency_step = 20, window_shape = "Gaussian")

  result <- get_spectral_moments_batch(spg)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("time", "cog", "sd", "skewness", "kurtosis"))
  expect_gt(nrow(result), 0)
  expect_type(result$time,     "double")
  expect_type(result$cog,      "double")
  expect_type(result$sd,       "double")
  expect_type(result$skewness, "double")
  expect_type(result$kurtosis, "double")
})

test_that("get_spectral_moments_batch() matches per-frame Spectrum calls", {
  skip_on_cran()

  sound <- Sound$create_tone(frequency = 440, duration = 0.2)
  spg   <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000, time_step = 0.002, frequency_step = 20, window_shape = "Gaussian")

  batch <- get_spectral_moments_batch(spg, power = 2.0)

  # Compare a few frames against the R-loop reference
  n_frames <- nrow(batch)
  check_idx <- unique(c(1, ceiling(n_frames / 2), n_frames))

  for (ix in check_idx) {
    t    <- batch$time[ix]
    spec <- spg$to_spectrum(t)

    cog_ref <- spec$get_centre_of_gravity(2.0)
    sd_ref  <- spec$get_standard_deviation(2.0)

    if (!is.na(batch$cog[ix]) && !is.na(cog_ref))
      expect_equal(batch$cog[ix], cog_ref, tolerance = 1e-6,
        info = paste("CoG mismatch at frame", ix, "t=", round(t, 4)))
    if (!is.na(batch$sd[ix]) && !is.na(sd_ref))
      expect_equal(batch$sd[ix], sd_ref, tolerance = 1e-6,
        info = paste("SD mismatch at frame", ix, "t=", round(t, 4)))
  }
})

test_that("get_spectral_moments_batch() accessible as Spectrogram method", {
  skip_on_cran()

  sound  <- Sound$create_tone(frequency = 440, duration = 0.2)
  spg    <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  result <- spg$get_spectral_moments_batch(power = 2.0)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("time", "cog", "sd", "skewness", "kurtosis"))
})

test_that("get_spectral_moments_batch() CoG is in audible frequency range", {
  skip_on_cran()

  # 1 kHz tone: CoG should cluster around 1000 Hz
  sound <- Sound$create_tone(frequency = 1000, duration = 0.3)
  spg   <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000, time_step = 0.002, frequency_step = 20, window_shape = "Gaussian")

  batch <- get_spectral_moments_batch(spg)
  valid_cog <- batch$cog[!is.na(batch$cog)]

  expect_gt(length(valid_cog), 0)
  # Median CoG should be in 0–5000 Hz range (the analysis range)
  expect_true(median(valid_cog) > 0 && median(valid_cog) < 5000,
    info = paste("Median CoG:", round(median(valid_cog)), "Hz"))
})
