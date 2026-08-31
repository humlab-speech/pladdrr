# test-voice-report.R - Regression test for PointProcess$voice_report()
#  arg-order bug

test_that("voice_report() returns sane, in-range statistics", {
  sound <- Sound$create_tone(frequency = 150, duration = 1.0,
    sampling_rate = 16000)
  pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- pitch$to_point_process()

  report <- pp$voice_report(sound, pitch)

  expect_type(report, "list")

  # These fields are fed silence_threshold/voicing_threshold as *fractions*.
  # Under the old arg-order bug they received max_period_factor (1.3) and
  # max_amplitude_factor (1.6) instead - both out of the valid [0, 1] range -
  # which made fraction_unvoiced_frames/degree_of_voice_breaks nonsensical.
  expect_gte(report$fraction_unvoiced_frames,
    0); expect_lte(report$fraction_unvoiced_frames, 1)
  expect_gte(report$degree_of_voice_breaks,
    0); expect_lte(report$degree_of_voice_breaks, 1)

  # A clean synthetic tone should be mostly voiced with low jitter.
  expect_lt(report$fraction_unvoiced_frames, 0.5)
  expect_gte(report$jitter_local, 0); expect_lt(report$jitter_local, 0.1)

  # median_pitch should be near the synthesized frequency.
  expect_lt(abs(report$median_pitch - 150) / 150, 0.1)
})

test_that(
  "voice_report() accepts silence_threshold/voicing_threshold and rejects bad types", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)
  pitch <- sound$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
  pp <- pitch$to_point_process()

  report <- pp$voice_report(sound, pitch, silence_threshold = 0.05,
    voicing_threshold = 0.5)
  expect_type(report, "list")

  expect_error(pp$voice_report("not a sound", pitch))
  expect_error(pp$voice_report(sound, "not a pitch"))
})
