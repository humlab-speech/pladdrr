# Exercises the pitch SIMD bridge (src/pitch_simd_bridge.cpp) end-to-end
# through the public Sound$to_pitch_ac()/to_pitch_cc() API with SIMD forced
# on, rather than testing the isolated autocorrelation helper directly.
# `NUMautocorrelation*_simd_bridge` is called from Sound_to_Pitch_any(),
# which both to_pitch_ac() (method = AC_HANNING/AC_GAUSS) and to_pitch_cc()
# (method = FCC_NORMAL/FCC_ACCURATE) route through -- see
# src/praat.github.io/fon/Sound_to_Pitch.cpp:108-141.
#
# NOTE on src/pitch_filter_simd.cpp (the Gaussian-lowpass-on-spectrum SIMD
# bridge gated by should_use_simd_for_pitch_filter(), used inside
# Sound_to_Pitch_filteredAc/filteredCc at Sound_to_Pitch.cpp:577-696):
# this branch has NO R-reachable entry point in pladdrr. The R API only
# exposes to_pitch()/to_pitch_ac()/to_pitch_cc()/to_pitch_shs() (see
# R/sound-wrapper.R), none of which call Sound_to_Pitch_filteredAc/Cc.
# Those two Praat functions are only invoked from Praat's own GUI command
# layer (praat.github.io/fon/praat_Sound.cpp's
# CONVERT_EACH_TO_ONE__Sound_to_Pitch_filtered{Autocorrelation,
# CrossCorrelation} forms, dispatched only through Praat's interactive
# script interpreter) and from praat.github.io/foned/SoundAnalysisArea.cpp
# (Praat's GUI pitch display) -- neither of which pladdrr's Rcpp layer
# drives. There is no "fcc" method argument anywhere in the R API (checked
# R/pitch-wrapper.R and R/sound-wrapper.R): to_pitch()'s only tunables are
# time_step/pitch_floor/pitch_ceiling, and to_pitch_cc() already reaches
# Sound_to_Pitch_any()'s FCC_NORMAL/FCC_ACCURATE branch on its own -- that
# is the "raw" cross-correlation method, not the "filtered" one that owns
# pitch_filter_simd.cpp. So pitch_filter_simd.cpp is dead code from the R
# surface as things stand; it cannot be exercised by any test written
# against the public API without adding a new R-level wrapper for
# Sound_to_Pitch_filteredAc/Cc, which is out of scope here. See the task-3
# report for this finding.

test_that("Pitch AC/CC SIMD path (pitch_simd_bridge.cpp) matches scalar for a real signal", {
  sound <- Sound$create_tone(duration = 1.0, sampling_rate = 44100, frequency = 180)

  pladdrr_simd(FALSE)
  pitch_scalar_ac <- sound$to_pitch_ac()
  pitch_scalar_cc <- sound$to_pitch_cc()

  pladdrr_simd(TRUE)
  pitch_simd_ac <- sound$to_pitch_ac()
  pitch_simd_cc <- sound$to_pitch_cc()

  expect_equal(pitch_simd_ac$get_number_of_frames(), pitch_scalar_ac$get_number_of_frames())
  expect_equal(pitch_simd_cc$get_number_of_frames(), pitch_scalar_cc$get_number_of_frames())

  # autocorrelation SIMD bridge must be bit-exact -- it's a direct arithmetic
  # reduction, not an FFT-order-dependent path like Harmonicity AC
  expect_equal(pitch_simd_ac$get_mean(), pitch_scalar_ac$get_mean(), tolerance = 1e-10)
  expect_equal(pitch_simd_cc$get_mean(), pitch_scalar_cc$get_mean(), tolerance = 1e-10)

  pladdrr_simd(TRUE) # restore default
})

test_that("Pitch AC/CC SIMD path matches scalar on a noisier/unvoiced-mixed signal", {
  # A second, less trivial fixture (tone + silence gaps) so the SIMD bridge
  # is exercised across both voiced and unvoiced frames, not just one clean
  # periodic tone.
  tone <- Sound$create_tone(duration = 0.5, sampling_rate = 44100, frequency = 220)
  silence <- Sound$create_tone(duration = 0.2, sampling_rate = 44100, frequency = 220, amplitude = 0)
  sound <- tone$concatenate_sounds(list(tone, silence, tone))

  pladdrr_simd(FALSE)
  scalar_ac <- sound$to_pitch_ac()
  scalar_cc <- sound$to_pitch_cc()

  pladdrr_simd(TRUE)
  simd_ac <- sound$to_pitch_ac()
  simd_cc <- sound$to_pitch_cc()

  expect_equal(simd_ac$get_mean(), scalar_ac$get_mean(), tolerance = 1e-10)
  expect_equal(simd_cc$get_mean(), scalar_cc$get_mean(), tolerance = 1e-10)
  expect_equal(simd_ac$count_voiced_frames(), scalar_ac$count_voiced_frames())
  expect_equal(simd_cc$count_voiced_frames(), scalar_cc$count_voiced_frames())

  pladdrr_simd(TRUE) # restore default
})
