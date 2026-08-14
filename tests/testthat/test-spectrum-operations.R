# test-spectrum-operations.R - Tests for R/spectrum-operations.R

spectrum_of_tone <- function(freq = 150, dur = 0.5, sr = 16000) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)$to_spectrum()
}

test_that("spectrum_cepstral_smoothing returns a new smoothed Spectrum", {
  spec <- spectrum_of_tone()
  smoothed <- spectrum_cepstral_smoothing(spec, bandwidth = 500)

  expect_s3_class(smoothed, "Spectrum")
  expect_false(identical(smoothed$.xptr, spec$.xptr))
})

test_that("spectrum_pass_hann_band modifies the spectrum in place and returns NULL invisibly", {
  spec <- spectrum_of_tone()
  result <- spectrum_pass_hann_band(spec, fmin = 300, fmax = 3000, smooth = 100)

  expect_null(result)
})

test_that("spectrum_stop_hann_band modifies the spectrum in place and returns NULL invisibly", {
  spec <- spectrum_of_tone()
  result <- spectrum_stop_hann_band(spec, fmin = 50, fmax = 100, smooth = 50)

  expect_null(result)
})
