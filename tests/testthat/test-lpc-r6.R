# test-lpc-r6.R - Tests for R/lpc-wrapper.R (LPC object)

test_that("LPC constructs from Sound via Burg method and reports basic properties", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  expect_s3_class(lpc, "LPC")
  expect_true(lpc$is_valid())
  expect_gte(lpc$get_number_of_frames(), 1)
  expect_type(lpc$get_time_step(), "double")
  expect_type(lpc$get_sampling_period(), "double")
  expect_gte(lpc$get_max_num_coefficients(), 1)
})

test_that("LPC per-frame coefficient/gain queries work", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  expect_type(lpc$get_gain_at_frame(1), "double")
  expect_type(lpc$get_coefficients_at_frame(1), "double")
  expect_type(lpc$get_all_gains(), "double")
  expect_true(is.matrix(lpc$get_all_coefficients()))
})

test_that("LPC conversions: to_spectrum, to_matrix, to_spectrogram, to_lfcc", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  spec <- lpc$to_spectrum(time = 0.1)
  expect_s3_class(spec, "Spectrum")

  mat <- lpc$to_matrix()
  expect_s3_class(mat, "Matrix")

  sgram <- lpc$to_spectrogram()
  expect_s3_class(sgram, "Spectrogram")

  lfcc <- lpc$to_lfcc(num_coefficients = 12)
  expect_s3_class(lfcc, "LFCC")
})

test_that("LPC filter_inverse_at_time performs inverse filtering", {
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  at_time <- lpc$filter_inverse_at_time(sound, time = 0.1)
  expect_s3_class(at_time, "Sound")

  expect_output(print(lpc), "Praat LPC")
})

test_that("LPC filter_inverse (whole-sound) is broken for the real Sound implementation", {
  # `.lpc_sound_filter_inverse_r6()` (src/lpc_wrappers.cpp) extracts the
  # external pointer assuming an R6-style object (`.__enclos_env__`,
  # `private$ptr`), but pladdrr's Sound() constructor (R/sound-wrapper.R)
  # builds a plain S3 list, not R6/S4. Rcpp::S4's constructor rejects the
  # list outright. filter_inverse_at_time() sidesteps this by passing
  # sound$get_xptr() directly and works correctly (see test above) -- this
  # confirms filter_inverse() itself is unreachable/broken, not a test
  # setup mistake.
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()

  expect_error(lpc$filter_inverse(sound), "S4")
})

test_that("LPC to_formant is unavailable in this build (hard-coded stop, no CLAPACK probe)", {
  # R/lpc-wrapper.R's to_formant() unconditionally stop()s regardless of
  # actual CLAPACK availability -- it's not a runtime capability check.
  sound <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
  lpc <- sound$to_lpc_burg()
  expect_error(lpc$to_formant(), regexp = "CLAPACK|not available")
})
