# tests/testthat/test-wrapper-small-gaps.R
# Consolidated coverage gap-fill for the remaining small branches across
# the wrapper files: constructor validations, the $ accessor's .pointer and
# unknown-method branches, S3 print/convert methods, matrix_create, and the
# praat-interpreter helpers.

snd <- function() Sound$create_tone(frequency = 220, duration = 0.3,
  sampling_rate = 16000)

test_that("wrapper constructors validate their xptr", {
  expect_error(Intensity(.xptr = NULL), "to_intensity")
  expect_error(Spectrogram(.xptr = NULL), "to_spectrogram")
  expect_error(SpectrumTier(.xptr = NULL), "Ltas")
  expect_error(PowerCepstrogram(.xptr = NULL), "external pointer")
})

test_that("wrapper $ accessor .pointer and unknown-method branches", {
  sg <- snd()$to_spectrogram()
  it <- snd()$to_intensity()
  st <- snd()$to_ltas()$to_spectrum_tier_peaks()
  expect_type(sg$.pointer, "externalptr")
  expect_type(it$.pointer, "externalptr")
  expect_type(st$.pointer, "externalptr")
  expect_null(sg$no_such_method)
  expect_null(it$no_such_method)
  expect_null(st$no_such_method)
})

test_that("S3 print and convert methods", {
  sg <- snd()$to_spectrogram()
  it <- snd()$to_intensity()
  st <- snd()$to_ltas()$to_spectrum_tier_peaks()
  m <- Matrix(numberOfRows = 3, numberOfColumns = 4)
  expect_output(print(sg), "Spectrogram")
  expect_invisible(print(sg))
  expect_output(print(it), "Intensity")
  expect_invisible(print(it))
  expect_output(print(st), "SpectrumTier")
  expect_output(print(m), "Matrix")
  expect_true(is.matrix(as.matrix(m)))
  expect_s3_class(as.data.frame(it), "data.frame")
})

test_that("matrix_create named-args constructor", {
  m <- matrix_create(xmin = 0, xmax = 1, nx = 10, dx = 0.1, x1 = 0,
                     ymin = 0, ymax = 1, ny = 5, dy = 0.2, y1 = 0)
  expect_s3_class(m, "Matrix")
  expect_identical(m$get_nx(), 10L)
  expect_identical(m$get_ny(), 5L)
})

test_that("praat-interpreter helpers validate input", {
  expect_error(pladdrr:::.check_character1(123), "single non-empty character")
  expect_error(pladdrr:::.check_character1(""), "single non-empty character")
  expect_invisible(pladdrr:::.check_character1("ok"))
  expect_error(praat_run_script(123), "single non-empty character")
  expect_invisible(praat_run_script("writeInfoLine: \"hi\""))
})
