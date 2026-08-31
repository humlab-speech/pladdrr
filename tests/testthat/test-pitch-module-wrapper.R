# test-pitch-module-wrapper.R - Tests for R/pitch-module.R (PitchModule S3
#  wrapper)

pitch_module_ptr <- function() {
  snd <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)
  pitch <- snd$to_pitch()
  pitch$.xptr
}

test_that("pitch_unit_code maps known units and rejects unknown ones", {
  expect_equal(pladdrr:::pitch_unit_code("hertz"), 0L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::pitch_unit_code("Hz"), 0L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::pitch_unit_code("semitones"), 1L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::pitch_unit_code("mel"), 2L,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(pladdrr:::pitch_unit_code("erb"), 3L,
    tolerance = sqrt(.Machine$double.eps))
  expect_error(pladdrr:::pitch_unit_code("bogus"), "Unknown unit")
})

test_that("PitchModule() requires a pointer", {
  expect_error(PitchModule(), "Sound\\$to_pitch")
})

test_that(
  "PitchModule() constructs a valid wrapper from a Sound-derived pointer", {
  pm <- PitchModule(pitch_module_ptr())

  expect_s3_class(pm, "PitchModule")
  expect_s3_class(pm, "PraatObjectModule")
  expect_true(pm$is_valid)
  expect_gt(pm$duration, 0)
  expect_gt(pm$nx, 0)
  expect_gt(pm$dx, 0)
})

test_that("print.PitchModule reports summary statistics without erroring", {
  pm <- PitchModule(pitch_module_ptr())
  out <- capture.output(print(pm))

  expect_true(any(grepl("Praat Pitch (Module)", out, fixed = TRUE)))
  expect_true(any(grepl("Duration:", out, fixed = TRUE)))
  expect_true(any(grepl("Frames:", out, fixed = TRUE)))
})

test_that("as.data.frame.PitchModule returns a data frame with expected rows", {
  pm <- PitchModule(pitch_module_ptr())
  df <- as.data.frame(pm)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), pm$nx, tolerance = sqrt(.Machine$double.eps))
})

test_that("$.PitchModule dispatches query methods with unit conversion", {
  pm <- PitchModule(pitch_module_ptr())

  mean_hz <- pm$get_mean(0, 0, "hertz")
  expect_true(is.numeric(mean_hz))

  sd_hz <- pm$get_standard_deviation(0, 0, "hertz")
  expect_true(is.numeric(sd_hz))

  q50 <- pm$get_quantile(0, 0, 0.5, "hertz")
  expect_true(is.numeric(q50))

  min_hz <- pm$get_minimum(0, 0, "hertz", TRUE)
  max_hz <- pm$get_maximum(0, 0, "hertz", TRUE)
  expect_true(is.numeric(min_hz))
  expect_true(is.numeric(max_hz))
  expect_true(max_hz >= min_hz || is.na(max_hz) || is.na(min_hz))

  val_at_0 <- pm$get_value_at_time(pm$duration / 2, "hertz", TRUE)
  expect_true(is.numeric(val_at_0))

  strength <- pm$get_strength_at_time(pm$duration / 2, "hertz", TRUE)
  expect_true(is.numeric(strength))

  mean_strength <- pm$get_mean_strength(0, 0, "hertz")
  expect_true(is.numeric(mean_strength))
})

test_that("$.PitchModule as_data_frame accessor mirrors as.data.frame()", {
  pm <- PitchModule(pitch_module_ptr())
  df <- pm$as_data_frame(FALSE, FALSE)

  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), pm$nx, tolerance = sqrt(.Machine$double.eps))
})

test_that("$.PitchModule to_point_process transform returns a PointProcess", {
  pm <- PitchModule(pitch_module_ptr())
  pp <- pm$to_point_process()

  expect_false(is.null(pp))
})
