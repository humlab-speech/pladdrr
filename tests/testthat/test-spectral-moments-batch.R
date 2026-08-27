# test-spectral-moments-batch.R
# Regression tests for PERF-1: get_spectral_moments_batch()

test_that("get_spectral_moments_batch() returns correct shape", {

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

  sound  <- Sound$create_tone(frequency = 440, duration = 0.2)
  spg    <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000)
  result <- spg$get_spectral_moments_batch(power = 2.0)

  expect_s3_class(result, "data.frame")
  expect_named(result, c("time", "cog", "sd", "skewness", "kurtosis"))
})

test_that("get_spectral_moments_batch() CoG is in audible frequency range", {

  # 1 kHz tone: CoG should cluster around 1000 Hz
  sound <- Sound$create_tone(frequency = 1000, duration = 0.3)
  spg   <- sound$to_spectrogram(window_length = 0.005, max_frequency = 5000, time_step = 0.002, frequency_step = 20, window_shape = "Gaussian")

  batch <- get_spectral_moments_batch(spg)
  valid_cog <- batch$cog[!is.na(batch$cog)]

  expect_gt(length(valid_cog), 0)
  # Median CoG should be in 0–5000 Hz range (the analysis range)
  expect_gt(median(valid_cog), 0)
  expect_lt(median(valid_cog), 5000)
})

test_that("get_spectral_moments_batch() rejects a null pointer at the C++ layer", {
  # get_spectral_moments_batch() requires inherits(spectrogram, "Spectrogram")
  # with no externalptr fallback, so its C++ null-pointer guard can only be
  # reached via the internal .get_spectral_moments_batch() export.
  null_ptr <- methods::new("externalptr")
  expect_error(
    pladdrr:::.get_spectral_moments_batch(null_ptr, 2.0),
    "Invalid Spectrogram pointer"
  )
})

test_that("get_spectral_moments_batch() computes moments for power != 2 (the default in every other test)", {
  # Every other test in this file uses the default power = 2.0, which skips
  # the pow(val, halfpower) branch (energy = val directly when
  # halfpower == 1.0). power = 1.0 (halfpower = 0.5) exercises it.
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  spg <- sound$to_spectrogram()

  result <- get_spectral_moments_batch(spg, power = 1.0)
  expect_true(!all(is.na(result$cog)))
})

test_that("get_spectral_moments_batch() returns all-NA moments for a silent (zero-energy) frame", {
  # A zero-amplitude sound has no positive spectrogram bins in any frame,
  # exercising the "zero total energy -> NA for this frame" branch that no
  # other test (all of which use audible tones) reaches.
  silence <- Sound$create_tone(frequency = 0, duration = 0.3, sampling_rate = 16000)
  spg <- silence$to_spectrogram()

  result <- get_spectral_moments_batch(spg)
  expect_true(all(is.na(result$cog)))
  expect_true(all(is.na(result$sd)))
  expect_true(all(is.na(result$skewness)))
  expect_true(all(is.na(result$kurtosis)))
})

test_that("get_spectral_moments_batch() returns sd = 0, skewness/kurtosis = NA for single-bin (zero-variance) frames", {
  # A very coarse frequency_step concentrates almost all of a pure tone's
  # energy into a single positive spectrogram bin per frame, so the central
  # moment about the CoG is exactly zero -- the "m2 <= 0" branch, distinct
  # from the "zero total energy" (fully silent) case above.
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  spg <- sound$to_spectrogram(frequency_step = 4000, window_length = 0.005)

  result <- get_spectral_moments_batch(spg)
  zero_sd <- which(result$sd == 0)
  expect_gt(length(zero_sd), 0)
  expect_true(all(is.na(result$skewness[zero_sd])))
  expect_true(all(is.na(result$kurtosis[zero_sd])))
})
