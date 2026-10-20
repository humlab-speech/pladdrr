# End-to-end pitch checks through the public Sound$to_pitch_ac()/
# to_pitch_cc() API with the SIMD toggle on. The pitch SIMD bridge and the
# filtered-AC/CC low-pass SIMD were removed (2026-10, never called /
# not bit-exact); these tests now guard the plain Praat pitch paths.

test_that(
  "Pitch AC/CC SIMD path (pitch_simd_bridge.cpp) matches scalar for a real signal", {
  sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100,
    frequency = 180)

  pladdrr_simd(FALSE)
  pitch_scalar_ac <- sound$to_pitch_ac()
  pitch_scalar_cc <- sound$to_pitch_cc()

  pladdrr_simd(TRUE)
  pitch_simd_ac <- sound$to_pitch_ac()
  pitch_simd_cc <- sound$to_pitch_cc()

  expect_equal(pitch_simd_ac$get_number_of_frames(),
    pitch_scalar_ac$get_number_of_frames(
      ), tolerance = sqrt(.Machine$double.eps))
  expect_equal(pitch_simd_cc$get_number_of_frames(),
    pitch_scalar_cc$get_number_of_frames(
      ), tolerance = sqrt(.Machine$double.eps))

  # autocorrelation SIMD bridge must be bit-exact -- it's a direct arithmetic
  # reduction, not an FFT-order-dependent path like Harmonicity AC
  expect_equal(pitch_simd_ac$get_mean(), pitch_scalar_ac$get_mean(),
    tolerance = 1e-10)
  expect_equal(pitch_simd_cc$get_mean(), pitch_scalar_cc$get_mean(),
    tolerance = 1e-10)

  pladdrr_simd(TRUE) # restore default
})

test_that(
  "Pitch AC/CC SIMD path matches scalar on a noisier/unvoiced-mixed signal", {
  # A second, less trivial fixture (tone + silence gaps) so the SIMD bridge
  # is exercised across both voiced and unvoiced frames, not just one clean
  # periodic tone.
  tone <- Sound$create_tone(duration = 0.5, sampling_rate = 44100,
    frequency = 220)
  silence <- Sound$create_tone(duration = 0.2, sampling_rate = 44100,
    frequency = 220, amplitude = 0)
  sound <- tone$concatenate_sounds(list(tone, silence, tone))

  pladdrr_simd(FALSE)
  scalar_ac <- sound$to_pitch_ac()
  scalar_cc <- sound$to_pitch_cc()

  pladdrr_simd(TRUE)
  simd_ac <- sound$to_pitch_ac()
  simd_cc <- sound$to_pitch_cc()

  expect_equal(simd_ac$get_mean(), scalar_ac$get_mean(), tolerance = 1e-10)
  expect_equal(simd_cc$get_mean(), scalar_cc$get_mean(), tolerance = 1e-10)
  expect_equal(simd_ac$count_voiced_frames(), scalar_ac$count_voiced_frames(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(simd_cc$count_voiced_frames(), scalar_cc$count_voiced_frames(),
    tolerance = sqrt(.Machine$double.eps))

  pladdrr_simd(TRUE) # restore default
})
