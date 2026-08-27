# tests/testthat/test-bark-mel-spectrogram-gaps.R
# Coverage gap-fill for the BarkSpectrogram and MelSpectrogram wrapper
# objects (R/bark-spectrogram-wrapper.R, R/mel-spectrogram-wrapper.R):
# to_intensity(), as_matrix(), to_mfcc() and print() were uncovered.

sound_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
}

# ---------------------------------------------------------------------------
# BarkSpectrogram wrapper methods

test_that("BarkSpectrogram$to_intensity returns an Intensity", {
  bark <- sound_fixture()$to_bark_spectrogram()
  intensity <- bark$to_intensity()
  expect_s3_class(intensity, "Intensity")
  expect_true(intensity$is_valid())
})

test_that("BarkSpectrogram$as_matrix returns a numeric matrix", {
  bark <- sound_fixture()$to_bark_spectrogram()
  mat <- bark$as_matrix()
  expect_type(mat, "double")
  expect_true(is.matrix(mat))
  expect_gt(nrow(mat), 0)
  expect_gt(ncol(mat), 0)
})

test_that("BarkSpectrogram$print prints a header and returns the object invisibly", {
  bark <- sound_fixture()$to_bark_spectrogram()
  expect_output(bark$print(), "<Praat BarkSpectrogram>")
  expect_invisible(bark$print())
})

# ---------------------------------------------------------------------------
# MelSpectrogram wrapper methods

test_that("MelSpectrogram$to_intensity returns an Intensity", {
  mel <- sound_fixture()$to_mel_spectrogram()
  intensity <- mel$to_intensity()
  expect_s3_class(intensity, "Intensity")
  expect_true(intensity$is_valid())
})

test_that("MelSpectrogram$as_matrix returns a numeric matrix", {
  mel <- sound_fixture()$to_mel_spectrogram()
  mat <- mel$as_matrix()
  expect_type(mat, "double")
  expect_true(is.matrix(mat))
  expect_gt(nrow(mat), 0)
  expect_gt(ncol(mat), 0)
})

test_that("MelSpectrogram$to_mfcc returns an MFCC", {
  mel <- sound_fixture()$to_mel_spectrogram()
  mfcc <- mel$to_mfcc(number_of_coefficients = 12L)
  expect_s3_class(mfcc, "MFCC")
})
