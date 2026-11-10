## One pitch-unit table, taken from Praat's kPitch_unit enum
## (src/praat.github.io/fon/Pitch_enums.h):
##   0 HERTZ, 1 HERTZ_LOGARITHMIC, 2 MEL, 3 LOG_HERTZ,
##   4-7 SEMITONES re 1/100/200/440 Hz, 8 ERB.
## Before 5.2.0 four R tables disagreed with it, so unit = "semitones" and "erb"
## returned log10(Hz) and unit = "banana" answered in hertz at the direct doors.
## The expected numbers below are Praat's own conversion formulas, applied to the
## hertz value the same object returns.

# melder/NUMear.cpp: NUMhertzToErb
hz_to_erb <- function(f) 11.17 * log((f + 312) / (f + 14680)) + 43
hz_to_mel <- function(f) 550 * log(1 + f / 550)

test_that(".pitch_unit_code is the kPitch_unit enum", {
  code <- pladdrr:::.pitch_unit_code
  expect_identical(code("hertz"), 0L)
  expect_identical(code("Hz"), 0L)
  expect_identical(code("hertz_logarithmic"), 1L)
  expect_identical(code("mel"), 2L)
  expect_identical(code("loghertz"), 3L)
  expect_identical(code("semitones_re_1hz"), 4L)
  expect_identical(code("semitones_re_100hz"), 5L)
  expect_identical(code("semitones_re_200hz"), 6L)
  expect_identical(code("semitones_re_440hz"), 7L)
  expect_identical(code("erb"), 8L)
  # a bare "semitones" is Praat's default, semitones re 100 Hz
  expect_identical(code("semitones"), 5L)
  expect_identical(code("ST"), 5L)
})

test_that("an unknown pitch unit is an input error, never hertz", {
  for (bad in list("banana", "semitone", "", NA_character_, 3, c("hertz", "mel"))) {
    cond <- tryCatch(pladdrr:::.pitch_unit_code(bad), error = function(e) e)
    expect_s3_class(cond, "pladdrr_input_error")
    expect_identical(cond$param, "unit")
    expect_match(conditionMessage(cond), "Unknown unit")
  }
})

test_that("Pitch units return Praat's numbers through every door", {
  s <- Sound$create_tone(1.0, 44100, 150, 0.5)
  p <- s$to_pitch_cc()
  hz <- p$get_value_at_time(0.5)
  expect_equal(hz, 150, tolerance = 1e-3)

  expect_equal(p$get_value_at_time(0.5, unit = "mel"), hz_to_mel(hz), tolerance = 1e-12)
  expect_equal(p$get_value_at_time(0.5, unit = "erb"), hz_to_erb(hz), tolerance = 1e-12)
  expect_equal(p$get_value_at_time(0.5, unit = "semitones"), 12 * log2(hz / 100),
    tolerance = 1e-12)
  expect_equal(p$get_value_at_time(0.5, unit = "semitones_re_1hz"), 12 * log2(hz),
    tolerance = 1e-12)
  expect_equal(p$get_value_at_time(0.5, unit = "semitones_re_440hz"),
    12 * log2(hz / 440), tolerance = 1e-12)
  expect_equal(p$get_value_at_time(0.5, unit = "loghertz"), log10(hz), tolerance = 1e-12)

  # the direct doors agree with the R6 door
  for (u in c("hertz", "mel", "erb", "semitones", "loghertz")) {
    expect_equal(get_pitch_value_direct(p$.xptr, 0.5, u),
      p$get_value_at_time(0.5, unit = u), tolerance = 1e-12, info = u)
  }
  expect_equal(get_pitch_mean_direct(p$.xptr, unit = "loghertz"),
    log10(get_pitch_mean_direct(p$.xptr)), tolerance = 1e-3)
  expect_equal(get_pitch_quantile_direct(p$.xptr, 0.5, unit = "erb"),
    hz_to_erb(get_pitch_quantile_direct(p$.xptr, 0.5)), tolerance = 1e-12)
})

test_that("the batch doors use the same table", {
  p <- Sound$create_tone(1.0, 44100, 150, 0.5)$to_pitch_cc()
  times <- c(0.3, 0.5, 0.7)
  hz <- get_pitch_at_times(p, times)
  expect_equal(get_pitch_at_times(p, times, unit = "semitones"), 12 * log2(hz / 100),
    tolerance = 1e-12)
  expect_equal(get_pitch_at_times(p, times, unit = "erb"), hz_to_erb(hz),
    tolerance = 1e-12)
  expect_error(get_pitch_at_times(p, times, unit = "banana"), "Unknown unit")
})

test_that("direct doors refuse an unknown unit", {
  p <- Sound$create_tone(0.5, 22050, 150, 0.5)$to_pitch_cc()
  expect_error(get_pitch_value_direct(p$.xptr, 0.25, "banana"), "Unknown unit")
  expect_error(p$get_value_at_time(0.25, unit = "banana"), "Unknown unit")
})
