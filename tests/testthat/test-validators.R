test_that("inverted or invalid pitch ranges error clearly at the R level", {
  s <- Sound$create_tone(frequency = 220, duration = 0.2)
  expect_error(s$to_pitch(pitch_floor = 600, pitch_ceiling = 75), "pitch_ceiling")
  expect_error(s$to_pitch(pitch_floor = -10), "pitch_floor")
  expect_error(s$to_pitch_cc(pitch_floor = 600, pitch_ceiling = 75), "pitch_ceiling")
  expect_error(s$to_manipulation(pitch_floor = 0), "pitch_floor")
  # valid range still works
  expect_s3_class(s$to_pitch(pitch_floor = 75, pitch_ceiling = 600), "Pitch")
})
