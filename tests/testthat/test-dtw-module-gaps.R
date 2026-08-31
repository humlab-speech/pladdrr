# test-dtw-module-gaps.R
# Coverage gap-fill for src/modules/dtw_module.cpp (Task 28)
#
# Complements test-dtw.R: closes gaps in domain properties (get_x_duration/
# get_y_duration/get_dx/get_dy), the reverse time-mapping methods
# (get_x_time_from_y_time / map_times("y_to_x")), the transformation methods
# (to_polygon/to_matrix_cumulative/to_duration_tier), TextGrid warping (both
# the success path and a real domain-mismatch error path), and the
# MFCC/Spectrogram/Pitch factory functions plus a real error path for each
# of the four factory functions (Sounds/MFCCs/Spectrograms/Pitches).
#
# Unlike test-dtw.R, these tests use generate_sine_wave() instead of the
# fixtures/speech_sample.wav fixture, so they run unconditionally (no
# skip_if_not()).

test_that("DTW x/y duration and dx/dy are accessible", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  expect_true(is.numeric(dtw$get_x_duration()))
  expect_true(is.numeric(dtw$get_y_duration()))
  expect_equal(dtw$get_x_duration(), dtw$get_xmax() - dtw$get_xmin(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(dtw$get_y_duration(), dtw$get_ymax() - dtw$get_ymin(), tolerance = sqrt(.Machine$double.eps))

  # get_dx()/get_dy() aren't exposed on the R6-style wrapper at all (only
  # get_nx()/get_ny() are); reach them via the raw .cpp module object.
  expect_gt(dtw$.cpp$get_dx(), 0)
  expect_gt(dtw$.cpp$get_dy(), 0)
})

test_that("DTW get_x_time_from_y_time maps time (reverse of get_y_time_from_x_time)", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  ty <- dtw$get_ymin() + dtw$get_y_duration() / 2
  tx <- dtw$get_x_time_from_y_time(ty)

  expect_true(is.finite(tx))
  # Self-alignment: mapped time should be close to input time.
  expect_equal(tx, ty, tolerance = 0.1)
})

test_that("DTW map_times y_to_x direction works (vectorized reverse mapping)", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  ymin <- dtw$get_ymin()
  ymax <- dtw$get_ymax()
  times <- seq(ymin, ymax, length.out = 5)

  mapped <- dtw$map_times(times, "y_to_x")

  expect_length(mapped, 5)
  expect_true(all(is.finite(mapped)))
})

test_that("DTW get_maximum_consecutive_steps rejects invalid direction at the C++ layer", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  # The R6-style wrapper's match.arg() already blocks bad `direction` values
  # before they reach C++; call the raw .cpp module directly to exercise
  # dtw_module.cpp's own guard ("direction must be 'x'/'horizontal' or
  # 'y'/'vertical'").
  expect_error(dtw$.cpp$get_maximum_consecutive_steps("diagonal"),
               "direction must be")
})

test_that("DTW to_polygon works and produces a valid Polygon", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  poly <- dtw$to_polygon()

  expect_s3_class(poly, "Polygon")
})

test_that("DTW to_matrix_cumulative works and produces a valid Matrix", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  mat <- dtw$to_matrix_cumulative()

  # Matrix is an S3-wrapped Praat object here, not a base R matrix, so
  # base nrow()/ncol() don't apply -- use its own get_nx()/get_ny().
  expect_s3_class(mat, "Matrix")
  expect_equal(mat$get_ny(), dtw$get_ny(), tolerance = sqrt(.Machine$double.eps))
  expect_equal(mat$get_nx(), dtw$get_nx(), tolerance = sqrt(.Machine$double.eps))
})

test_that("DTW to_duration_tier is an unimplemented Praat stub (documented, not fixed)", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  dtw <- sounds_to_dtw(sound, sound)

  # DTW_to_DurationTier() in praat.github.io/dwtools/DTW.cpp is a stub:
  #   autoDurationTier DTW_to_DurationTier (DTW /* me */) { return autoDurationTier(); }
  # It always returns a null/empty object rather than a real DurationTier.
  # This is an upstream Praat limitation (no real algorithm exists to call),
  # not a pladdrr bug -- documented here rather than fixed, per this
  # campaign's norm for anything beyond a zero-risk no-op.
  tier <- dtw$to_duration_tier()

  expect_s3_class(tier, "DurationTier")
  expect_false(tier$.cpp$is_valid())
})

test_that("DTW warp_textgrid warps a domain-matching TextGrid", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000, amplitude = 0.5)
  dtw <- sounds_to_dtw(sound, sound)

  pitch <- sound$to_pitch()
  tg <- pitch$to_textgrid_silences()

  warped <- dtw$warp_textgrid(tg)

  expect_s3_class(warped, "TextGrid")
})

test_that("DTW warp_textgrid errors on a TextGrid whose domain matches neither DTW axis", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000, amplitude = 0.5)
  dtw <- sounds_to_dtw(sound, sound)

  other_sound <- generate_sine_wave(220, 0.9, sampling_rate = 16000, amplitude = 0.5)
  other_pitch <- other_sound$to_pitch()
  mismatched_tg <- other_pitch$to_textgrid_silences()

  # Praat's DTW_TextGrid_to_TextGrid() (dwtools/DTW_and_TextGrid.cpp) requires
  # the TextGrid's domain to equal one of the DTW's x/y domains within
  # `precision`; a genuinely mismatched domain (0.3s DTW vs 0.9s TextGrid) is
  # a real, caught MelderError -> R error, not a crash (confirmed by reading
  # the guard in DTW_and_TextGrid.cpp before writing this test).
  expect_error(dtw$warp_textgrid(mismatched_tg))
})

test_that("sounds_to_dtw surfaces a real error for a sound shorter than the analysis window", {
  # analysis_width default is 0.025s; the Gaussian window duration used
  # internally is 2*analysis_width = 0.05s. Sampled_shortTermAnalysis()
  # (fon/Sampled.cpp) throws when the window duration exceeds the sound's own
  # duration -- a real, caught MelderError propagated up through
  # Sound_to_MFCC -> Sounds_to_DTW, not a crash (confirmed by reading
  # Sampled_shortTermAnalysis() before writing this test).
  tiny_sound <- generate_sine_wave(220, 0.01, sampling_rate = 16000)

  expect_error(sounds_to_dtw(tiny_sound, tiny_sound))
})

test_that("mfccs_to_dtw creates a valid DTW from two MFCC objects", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  mfcc1 <- sound$to_mfcc()
  mfcc2 <- sound$to_mfcc()

  dtw <- mfccs_to_dtw(mfcc1, mfcc2)

  expect_s3_class(dtw, "DTW")
  expect_true(dtw$.cpp$is_valid())
})

test_that("mfccs_to_dtw errors when the two MFCCs have a different number of mel filters", {
  # Note: MFCC's `maximumNumberOfCoefficients` is always (number of mel
  # filters - 1) -- see MelSpectrogram_to_MFCC() in
  # dwtools/Spectrogram_extensions.cpp -- it does NOT track the
  # `num_coefficients` argument to to_mfcc() (that only truncates the
  # per-frame coefficients actually filled in). So the mismatch has to come
  # from a different filter spacing (df_mel), not num_coefficients.
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  mfcc1 <- sound$to_mfcc(df_mel = 100)
  mfcc2 <- sound$to_mfcc(df_mel = 300)

  # CCs_to_DTW() (dwtools/CCs_to_DTW.cpp) requires
  # `my maximumNumberOfCoefficients == thy maximumNumberOfCoefficients`; a
  # mismatch is a real, caught MelderError -> R error, not a crash (confirmed
  # by reading the guard in CCs_to_DTW.cpp before writing this test).
  expect_error(mfccs_to_dtw(mfcc1, mfcc2))
})

test_that("spectrograms_to_dtw creates a valid DTW from two Spectrogram objects", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spec1 <- sound$to_spectrogram()
  spec2 <- sound$to_spectrogram()

  dtw <- spectrograms_to_dtw(spec1, spec2)

  expect_s3_class(dtw, "DTW")
  expect_true(dtw$.cpp$is_valid())
})

test_that("spectrograms_to_dtw errors when the two Spectrograms have different frequency ranges", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spec1 <- sound$to_spectrogram(max_frequency = 5000)
  spec2 <- sound$to_spectrogram(max_frequency = 4000)

  # Spectrograms_to_DTW() (dwtools/DTW.cpp) requires
  # `my xmin == thy xmin && my ymax == thy ymax && my ny == thy ny`; a
  # frequency-range mismatch is a real, caught MelderError -> R error, not a
  # crash (confirmed by reading the guard in DTW.cpp before writing this
  # test).
  expect_error(spectrograms_to_dtw(spec1, spec2))
})

test_that("pitches_to_dtw creates a valid DTW from two Pitch objects", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  pitch1 <- sound$to_pitch()
  pitch2 <- sound$to_pitch()

  dtw <- pitches_to_dtw(pitch1, pitch2)

  expect_s3_class(dtw, "DTW")
  expect_true(dtw$.cpp$is_valid())
})

test_that("pitches_to_dtw errors on a negative vuv_costs", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  pitch1 <- sound$to_pitch()
  pitch2 <- sound$to_pitch()

  # Pitches_to_DTW() (dwtools/DTW.cpp) requires `vuv_costs >= 0.0`; a negative
  # value is a real, caught MelderError -> R error, not a crash (confirmed by
  # reading the guard in DTW.cpp before writing this test).
  expect_error(pitches_to_dtw(pitch1, pitch2, vuv_costs = -1))
})
