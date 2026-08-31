# tests/testthat/test-interpreter-wrap-all.R
# Coverage gap-fill for the remaining .wrap_praat_object class-mapping
# arms: PointProcess, Harmonicity, LPC, Manipulation, Table, PitchTier,
# FormantGrid, IntensityTier, DurationTier, AmplitudeTier, Cochleagram,
# Excitation, Cepstrum, VocalTract, LongSound, FormantTier.

snd <- function() Sound$create_tone(frequency = 220, duration = 0.3,
  sampling_rate = 16000)

wrap_expect_class <- function(obj, expected) {
  ptr <- obj$.xptr
  attr(ptr, "praat_class") <- expected
  wrapped <- pladdrr:::.wrap_praat_object(ptr)
  expect_s3_class(wrapped, expected)
}

test_that(".wrap_praat_object maps every remaining class", {
  wrap_expect_class(snd()$to_pitch()$to_point_process(), "PointProcess")
  wrap_expect_class(snd()$to_harmonicity_cc(), "Harmonicity")
  wrap_expect_class(snd()$to_lpc_burg(), "LPC")
  wrap_expect_class(snd()$to_manipulation(), "Manipulation")
  wrap_expect_class(snd()$to_formant_burg()$down_to_table(), "Table")
  wrap_expect_class(snd()$to_pitch()$down_to_pitch_tier(), "PitchTier")
  wrap_expect_class(FormantGrid(tmin = 0, tmax = 1, number_of_formants = 2),
    "FormantGrid")
  wrap_expect_class(IntensityTier(tmin = 0, tmax = 1), "IntensityTier")
  wrap_expect_class(DurationTier(tmin = 0, tmax = 1), "DurationTier")
  wrap_expect_class(amplitude_tier_create(0, 1), "AmplitudeTier")
  wrap_expect_class(snd()$to_cochleagram(), "Cochleagram")
  wrap_expect_class(snd()$to_spectrum()$to_excitation(), "Excitation")
  wrap_expect_class(snd()$to_spectrum()$to_cepstrum(), "Cepstrum")
  wrap_expect_class(VocalTract(nx = 17L, dx = 0.01), "VocalTract")
  wav <- testthat::test_path("fixtures/sine_440hz.wav")
  skip_if_not(file.exists(wav))
  wrap_expect_class(longsound_open(wav), "LongSound")
  wrap_expect_class(FormantTier$from_formant(snd()$to_formant_burg()),
    "FormantTier")
})
