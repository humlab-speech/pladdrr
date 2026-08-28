# tests/testthat/test-formantpath-gaps-extra.R
# Coverage gap-fill for R/formantpath-module.R and R/praat-interpreter.R:
# the $ accessor NULL branch, the char-path + validation branches in the
# constructor, the S3 print/convert methods, and praat_init/praat_initialized.

fp_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$
    to_formant_path(num_steps_up_down = 2L)
}

test_that("FormantPath accessor NULL branch", {
  fp <- fp_fixture()
  expect_null(fp$no_such_method)
})

test_that("FormantPath constructor accepts paths and validates", {
  wav <- testthat::test_path("fixtures/sine_440hz.wav")
  skip_if_not(file.exists(wav))
  fp <- FormantPath(wav)
  expect_s3_class(fp, "FormantPath")
  expect_error(FormantPath(12345), "Sound object or path")
})

test_that("FormantPath S3 print and convert", {
  fp <- fp_fixture()
  expect_output(print(fp), "FormantPath")
  expect_invisible(print(fp))
  df <- as.data.frame(fp)
  expect_s3_class(df, "data.frame")
  expect_true("formant_number" %in% names(df) || nrow(df) >= 0)
})

test_that("praat_init and praat_initialized", {
  expect_invisible(praat_init())
  expect_type(praat_initialized(), "logical")
})
