## PitchTier$shift_frequencies(shift, unit). On 5.1.0 a "semitones" shift was a
## silent no-op (the contour came back unchanged) and "erb" shifted by logHertz,
## multiplying the frequencies by 10. Expected values are Praat's conversions
## (melder/NUMear.cpp) applied to the same point.

hz_to_mel <- function(f) 550 * log(1 + f / 550)
mel_to_hz <- function(m) 550 * (exp(m / 550) - 1)
hz_to_erb <- function(f) 11.17 * log((f + 312) / (f + 14680)) + 43
erb_to_hz <- function(e) {
  d <- exp((e - 43) / 11.17)
  (14680 * d - 312) / (1 - d)
}

shifted <- function(shift, unit) {
  tier <- Sound$create_tone(1.0, 22050, 150, 0.5)$to_pitch_cc()$down_to_pitch_tier()
  before <- tier$get_value_at_index(5)
  tier$shift_frequencies(shift, unit)
  c(before = before, after = tier$get_value_at_index(5))
}

test_that("PitchTier$shift_frequencies shifts in every supported unit", {
  v <- shifted(10, "hertz")
  expect_equal(v[["after"]], v[["before"]] + 10, tolerance = 1e-12)
  v <- shifted(1, "semitones")
  expect_equal(v[["after"]], v[["before"]] * 2^(1 / 12), tolerance = 1e-12)
  expect_false(isTRUE(all.equal(v[["after"]], v[["before"]])))
  v <- shifted(-3, "semitones_re_440hz")
  expect_equal(v[["after"]], v[["before"]] * 2^(-3 / 12), tolerance = 1e-12)
  v <- shifted(10, "mel")
  expect_equal(v[["after"]], mel_to_hz(hz_to_mel(v[["before"]]) + 10), tolerance = 1e-12)
  v <- shifted(0.1, "loghertz")
  expect_equal(v[["after"]], 10^(log10(v[["before"]]) + 0.1), tolerance = 1e-12)
  v <- shifted(1, "erb")
  expect_equal(v[["after"]], erb_to_hz(hz_to_erb(v[["before"]]) + 1), tolerance = 1e-12)
  expect_lt(v[["after"]], 2 * v[["before"]])  # 5.1.0 returned 10x
})

test_that("shift_frequencies refuses units it cannot shift in", {
  tier <- Sound$create_tone(1.0, 22050, 150, 0.5)$to_pitch_cc()$down_to_pitch_tier()
  before <- tier$get_value_at_index(5)
  expect_error(tier$shift_frequencies(1, "banana"), "Unknown unit")
  # hertz_logarithmic has no shift in Praat: refused, not a silent no-op
  cond <- tryCatch(tier$shift_frequencies(1, "hertz_logarithmic"), error = function(e) e)
  expect_s3_class(cond, "pladdrr_input_error")
  expect_match(conditionMessage(cond), "cannot shift")
  expect_equal(tier$get_value_at_index(5), before)
})

test_that("shift_frequencies_in_range uses the same units", {
  tier <- Sound$create_tone(1.0, 22050, 150, 0.5)$to_pitch_cc()$down_to_pitch_tier()
  before <- tier$get_value_at_index(5)
  tier$shift_frequencies_in_range(0, 1, 12, "semitones")
  expect_equal(tier$get_value_at_index(5), before * 2, tolerance = 1e-12)
})
