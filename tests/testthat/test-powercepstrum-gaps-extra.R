# tests/testthat/test-powercepstrum-gaps-extra.R
# Coverage gap-fill for R/powercepstrum.R (10 remaining uncovered lines):
# constructor validation, the $ accessor branches, and the S3 prints.

pc_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$
    to_spectrum()$to_power_cepstrum()
}
pcg_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$
    to_powercepstrogram()
}

test_that("PowerCepstrum/PowerCepstrogram constructor validation", {
  expect_error(PowerCepstrum(.xptr = NULL), "external pointer")
  expect_error(PowerCepstrum(.xptr = "not a pointer"), "external pointer")
  expect_error(PowerCepstrogram(.xptr = NULL), "external pointer")
})

test_that("PowerCepstrum/PowerCepstrogram $ accessor branches", {
  pc <- pc_fixture()
  expect_type(pc$.pointer, "externalptr")
  expect_null(pc$no_such_method)
  pg <- pcg_fixture()
  expect_type(pg$.pointer, "externalptr")
  expect_null(pg$no_such_method)
})

test_that("S3 print methods", {
  pc <- pc_fixture()
  expect_output(print(pc), "PowerCepstrum")
  expect_invisible(print(pc))
  pg <- pcg_fixture()
  expect_output(print(pg), "PowerCepstrogram")
})
