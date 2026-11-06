# tests/testthat/test-ltas-wrapper-gaps.R
# Coverage gap-fill for R/ltas-wrapper.R: .ltas_unit_code default, the
# constructor validation, $ accessor branches, S3 print/convert methods,
# ltas_average list-unwrap + error branch, and the spectral-trend print
# linear-model branch.

ltas_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)$to_ltas()
}

test_that(".ltas_unit_code maps units and defaults", {
  # F-faith-13: Praat's Ltas averaging CHOICE is 1-based with no MEDIAN, so
  # "dB" is 3 (fon/praat_uvafon_init.cpp:1101-1105), and an unknown spelling is
  # an error rather than a silent "energy" (it was 0L / 1L here before).
  expect_equal(pladdrr:::.ltas_unit_code("energy"), 1L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::.ltas_unit_code("sones"), 2L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::.ltas_unit_code("db"), 3L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::.ltas_unit_code("dB"), 3L,
    tolerance = sqrt(.Machine$double.eps))
  expect_error(pladdrr:::.ltas_unit_code("bogus_unit"), "energy")
})

test_that("Ltas constructor validation and accessor branches", {
  expect_error(Ltas(.xptr = NULL), "Sound or Spectrum")
  lt <- ltas_fixture()
  expect_type(lt$.pointer, "externalptr")
  expect_null(lt$no_such_method)
})

test_that("S3 print and convert methods", {
  lt <- ltas_fixture()
  expect_output(print(lt), "Ltas")
  expect_invisible(print(lt))
  expect_s3_class(as.data.frame(lt), "data.frame")
})

test_that("ltas_average handles lists, validates, and averages", {
  lt1 <- ltas_fixture()
  lt2 <- Sound$create_tone(frequency = 330, duration = 0.3,
    sampling_rate = 16000)$to_ltas()
  avg <- ltas_average(list(lt1, lt2))
  expect_s3_class(avg, "Ltas")
  expect_error(ltas_average(lt1, "not an ltas"), "All arguments must be Ltas")
})

test_that("spectral trend print covers the linear model", {
  trend <- ltas_fixture()$report_spectral_trend(fmin = 100, fmax = 5000,
    frequency_scale = "linear")
  expect_output(print(trend), "frequency_Hz")
  expect_invisible(print(trend))
})
