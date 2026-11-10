# G5.2b: every argument check in the batch, DTW and fast-access functions
# rejects the wrong kind of object with its own message.

snd <- generate_sine_wave(200, 0.3, sampling_rate = 16000, amplitude = 0.5)
pitch <- snd$to_pitch_cc()
formant <- snd$to_formant_burg()
mfcc <- snd$to_mfcc()
spec <- snd$to_spectrogram()
pp <- snd$to_point_process_periodic_cc(75, 600)
intens <- snd$to_intensity()
fake_sound <- structure(list(.xptr = NULL), class = c("Sound", "PraatObject"))

test_that("batch extractors reject elements that are not Sounds or pointers", {
  batch <- c("sound_extract_and_formant", "sound_extract_and_pitch", "sound_to_formant_batch",
             "sound_to_intensity_batch", "sound_to_pitch_ac_batch", "sound_to_pitch_batch",
             "sound_to_pitch_cc_batch", "sound_to_pitch_shs_batch", "sound_to_pitch_spinet_batch")
  for (fn in batch) {
    expect_error(get(fn)(list("a")),
                 paste0(fn, "(): Invalid input type: expected Sound or externalptr"), fixed = TRUE)
  }
  # a Sound-classed object without a pointer reaches the second check
  for (fn in setdiff(batch, c("sound_extract_and_formant", "sound_extract_and_pitch"))) {
    expect_error(get(fn)(list(fake_sound)),
                 paste0(fn, "(): Could not extract pointer from Sound object"), fixed = TRUE)
  }
})

test_that("textgrid_merge and get_durations_batch validate their arguments", {
  expect_error(textgrid_merge(list()), "textgrids must be a non-empty list", fixed = TRUE)
  tg <- TextGrid(path = system.file("extdata", "test.TextGrid", package = "pladdrr"))
  expect_error(textgrid_merge(list(tg), equalize_domains = "x"),
               "equalize_domains must be TRUE or FALSE", fixed = TRUE)
  expect_error(get_durations_batch(1), "file_paths must be a character vector", fixed = TRUE)
})

test_that("time-query helpers require non-empty numeric times", {
  expect_error(get_formants_at_times(formant, numeric(0)),
               "get_formants_at_times(): times must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_formants_at_times(formant, 0.1, formant_numbers = integer(0)),
               "formant_numbers must be a non-empty integer vector", fixed = TRUE)
  expect_error(get_formant_bandwidths_at_times(formant, numeric(0)),
               "get_formant_bandwidths_at_times(): times must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_pitch_at_times(pitch, numeric(0)),
               "get_pitch_at_times(): times must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_intensity_at_times(intens, numeric(0)),
               "get_intensity_at_times(): times must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_pointprocess_nearest_indices(pp, numeric(0)),
               "get_pointprocess_nearest_indices(): times must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_pitch_quantiles_batch(pitch, numeric(0), 0, 0),
               "quantiles must be a non-empty numeric vector", fixed = TRUE)
  expect_error(get_pitch_quantiles_batch(pitch, 2, 0, 0),
               "quantiles must be between 0 and 1", fixed = TRUE)
})

test_that("PointProcess queries reject other objects", {
  expect_error(get_jitter_shimmer_batch("a", snd),
               "pointprocess must be a PointProcess object or external pointer", fixed = TRUE)
  expect_error(get_pointprocess_intervals("a"),
               "get_pointprocess_intervals(): pointprocess must be a PointProcess object", fixed = TRUE)
  expect_error(get_pointprocess_nearest_indices("a", 1),
               "get_pointprocess_nearest_indices(): pointprocess must be a PointProcess object", fixed = TRUE)
  expect_error(get_pointprocess_times("a"),
               "get_pointprocess_times(): pointprocess must be a PointProcess object", fixed = TRUE)
})

test_that("DTW constructors and methods check the type of both operands", {
  expect_error(mfccs_to_dtw("a", mfcc), "mfcc1 must be an MFCC object", fixed = TRUE)
  expect_error(mfccs_to_dtw(mfcc, "a"), "mfcc2 must be an MFCC object", fixed = TRUE)
  expect_error(pitches_to_dtw("a", pitch), "pitch1 must be a Pitch object", fixed = TRUE)
  expect_error(pitches_to_dtw(pitch, "a"), "pitch2 must be a Pitch object", fixed = TRUE)
  expect_error(sounds_to_dtw("a", snd), "sounds_to_dtw(): reference must be a Sound object", fixed = TRUE)
  expect_error(sounds_to_dtw(snd, "a"), "candidate must be a Sound object", fixed = TRUE)
  expect_error(spectrograms_to_dtw("a", spec), "spectrogram1 must be a Spectrogram", fixed = TRUE)
  expect_error(spectrograms_to_dtw(spec, "a"), "spectrogram2 must be a Spectrogram", fixed = TRUE)
  expect_error(snd$to_dtw("a"), "sound$to_dtw(): reference must be a Sound object", fixed = TRUE)
  expect_error(mfcc$to_dtw("a"), "reference must be an MFCC object", fixed = TRUE)
  expect_error(pitch$to_dtw("a"), "reference must be a Pitch object", fixed = TRUE)
  expect_error(spec$to_dtw("a"), "reference must be a Spectrogram object", fixed = TRUE)
})

test_that("fast-access helpers require a Sound", {
  expect_error(get_sound_times_fast("a"), "get_sound_times_fast(): Input must be a Sound object", fixed = TRUE)
  expect_error(get_sound_values_fast("a"), "Input must be a Sound object created with Sound()", fixed = TRUE)
  expect_error(sound_as_matrix_fast("a"), "sound_as_matrix_fast(): Input must be a Sound object", fixed = TRUE)
})
