# tests/testthat/test-pitch-wrapper-gaps.R
# Coverage gap-fill for R/pitch-wrapper.R (was ~56%): the thin delegating
# Pitch R6 getters, the unit-code helper, and the analysis methods.

pitch_fixture <- function() {
  sound_fixture <- function() Sound$create_tone(frequency = 220,
    duration = 0.3, sampling_rate = 16000)
  sound_fixture()$to_pitch()
}

test_that(".pitch_unit_code maps units", {
  expect_identical(pladdrr:::.pitch_unit_code("hertz"), 0L)
  expect_identical(pladdrr:::.pitch_unit_code("Hertz"), 0L)
  expect_identical(pladdrr:::.pitch_unit_code("hz"), 0L)
  expect_identical(pladdrr:::.pitch_unit_code("semitones"), 1L)
  expect_identical(pladdrr:::.pitch_unit_code("mel"), 2L)
  expect_identical(pladdrr:::.pitch_unit_code("erb"), 3L)
  expect_error(pladdrr:::.pitch_unit_code("bogus"), "Unknown unit")
  expect_error(pladdrr:::.pitch_unit_code("semitone"), "Unknown unit")
})

test_that("Pitch time/duration/geometry getters", {
  p <- pitch_fixture()
  expect_true(p$is_valid())
  expect_gte(p$get_duration(), 0)
  expect_equal(p$get_total_duration(), p$get_duration(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(p$duration(), p$get_duration(),
    tolerance = sqrt(.Machine$double.eps))
  expect_lte(p$xmin(), p$xmax())
  expect_equal(p$get_start_time(), p$xmin(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(p$get_end_time(), p$xmax(),
    tolerance = sqrt(.Machine$double.eps))
  expect_gte(p$nx(), 1)
  expect_gt(p$dx(), 0)
  expect_equal(p$get_number_of_frames(), p$nx(),
    tolerance = sqrt(.Machine$double.eps))
  expect_gte(p$get_time_step(), 0)
})

test_that("Pitch frame/time conversion methods", {
  p <- pitch_fixture()
  n <- p$nx()
  if (n >= 1) {
    t1 <- p$get_time_from_frame(1)
    f1 <- p$get_frame_from_time(t1)
    expect_gte(f1, 1)
    expect_lte(f1, n)
  }
})

test_that("Pitch analysis methods return numeric values", {
  p <- pitch_fixture()
  v <- p$get_value_at_time(p$get_start_time() + 0.05, unit = "hertz")
  expect_type(v, "double")
  m <- p$get_mean(unit = "hertz")
  expect_type(m, "double")
  sd <- p$get_standard_deviation(unit = "hertz")
  expect_gte(sd, 0)
  q <- p$get_quantile(quantile = 0.5, unit = "hertz")
  expect_type(q, "double")
})

test_that("Pitch as_data_frame/down_to_pitch_tier", {
  p <- pitch_fixture()
  df <- p$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  tier <- p$down_to_pitch_tier()
  expect_s3_class(tier, "PitchTier")
})
