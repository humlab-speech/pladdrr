# test-manipulation-wrapper.R - Tests for R/manipulation-wrapper.R

manip_from_tone <- function() {
  snd <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)
  snd$to_manipulation(pitch_floor = 75, pitch_ceiling = 300)
}

test_that("Manipulation() requires a pointer", {
  expect_error(Manipulation(), "to_manipulation")
  expect_error(Manipulation(NULL), "to_manipulation")
})

test_that("Manipulation constructed from Sound$to_manipulation() is valid", {
  manip <- manip_from_tone()

  expect_s3_class(manip, "Manipulation")
  expect_s3_class(manip, "PraatObject")
  expect_true(manip$is_valid())
  expect_gt(manip$get_end_time(), manip$get_start_time())
  expect_equal(manip$get_duration(),
    manip$get_end_time() - manip$get_start_time(),
               tolerance = 1e-9)
})

test_that("Manipulation reports has_* tier flags", {
  manip <- manip_from_tone()

  expect_type(manip$has_pitch_tier(), "logical")
  expect_type(manip$has_duration_tier(), "logical")
  expect_type(manip$has_pulses(), "logical")
  expect_type(manip$has_original_sound(), "logical")
})

test_that("Manipulation can extract pitch tier, duration tier, and pulses", {
  manip <- manip_from_tone()

  pt <- manip$extract_pitch_tier()
  expect_s3_class(pt, "PitchTier")

  dt <- manip$extract_duration_tier()
  expect_s3_class(dt, "DurationTier")

  pp <- manip$extract_pulses()
  expect_s3_class(pp, "PointProcess")
})

test_that("Manipulation can extract the original sound", {
  manip <- manip_from_tone()

  snd <- manip$extract_original_sound()
  expect_s3_class(snd, "Sound")
  expect_gt(snd$get_duration(), 0)
})

test_that("Manipulation can replace pitch tier, duration tier, and pulses", {
  manip <- manip_from_tone()
  pt <- manip$extract_pitch_tier()
  dt <- manip$extract_duration_tier()
  pp <- manip$extract_pulses()

  expect_error(manip$replace_pitch_tier("not a pitch tier"), "PitchTier")
  expect_error(manip$replace_duration_tier("not a duration tier"),
    "DurationTier")
  expect_error(manip$replace_pulses("not a point process"), "PointProcess")

  expect_invisible(manip$replace_pitch_tier(pt))
  expect_invisible(manip$replace_duration_tier(dt))
  expect_invisible(manip$replace_pulses(pp))
})

test_that("Manipulation resynthesis methods return Sound objects", {
  manip <- manip_from_tone()

  overlap_add <- manip$get_resynthesis_overlap_add()
  expect_s3_class(overlap_add, "Sound")

  pulses <- manip$get_resynthesis_pulses()
  expect_s3_class(pulses, "Sound")
})

test_that("Manipulation$get_xptr() returns the underlying external pointer", {
  manip <- manip_from_tone()
  expect_type(manip$get_xptr(), "externalptr")
})

test_that("print.Manipulation prints a summary without erroring", {
  manip <- manip_from_tone()
  out <- capture.output(print(manip))

  expect_true(any(grepl("Praat Manipulation", out, fixed = TRUE)))
  expect_true(any(grepl("Time domain:", out, fixed = TRUE)))
  expect_true(any(grepl("Has pitch tier:", out, fixed = TRUE)))
})

test_that("unknown $ access on Manipulation returns NULL", {
  manip <- manip_from_tone()
  expect_null(manip$not_a_real_method)
})
