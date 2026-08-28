# tests/testthat/test-complexspectrogram-module-gaps.R
# Coverage gap-fill for R/complexspectrogram-module.R (was ~52%): the
# geometry getters, amplitude/phase queries, and conversions.

cs_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$to_complex_spectrogram()
}

test_that("ComplexSpectrogram geometry getters", {
  cs <- cs_fixture()
  expect_true(cs$is_valid())
  expect_gte(cs$nx(), 1L)
  expect_gt(cs$dx(), 0)
  expect_lte(cs$xmin(), cs$xmax())
  expect_gte(cs$ny(), 1L)
  expect_gt(cs$dy(), 0)
  expect_lte(cs$ymin(), cs$ymax())
})

test_that("ComplexSpectrogram amplitude/phase queries", {
  cs <- cs_fixture()
  t <- (cs$xmin() + cs$xmax()) / 2
  f <- (cs$ymin() + cs$ymax()) / 2
  a <- cs$get_amplitude(t, f)
  expect_type(a, "double")
  p <- cs$get_phase(t, f)
  expect_type(p, "double")
})

test_that("ComplexSpectrogram unknown method returns NULL", {
  cs <- cs_fixture()
  expect_null(cs$no_such_method)
})

test_that("ComplexSpectrogram constructor validation and print", {
  expect_error(ComplexSpectrogram("not a sound"), "must be a Sound")
  cs <- cs_fixture()
  expect_output(print(cs), "ComplexSpectrogram")
  expect_output(print(cs), "Time domain")
  expect_invisible(print(cs))
})

test_that("ComplexSpectrogram conversions", {
  cs <- cs_fixture()
  snd <- cs$to_sound()
  expect_s3_class(snd, "Sound")
  sg <- cs$to_spectrogram()
  expect_s3_class(sg, "Spectrogram")
  sp <- cs$to_spectrum(cs$xmin() + 0.05)
  expect_s3_class(sp, "Spectrum")
})
