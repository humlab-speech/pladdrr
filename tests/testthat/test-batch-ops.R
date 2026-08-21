# test-batch-ops.R - Tests for R/batch-ops.R batch-processing functions
# (only textgrid_merge was previously tested, in test-textgrid-merge.R;
#  this file covers the remaining 11 exported functions: sound_concatenate_all,
#  sound_to_pitch_batch, sound_to_pitch_ac_batch, sound_to_pitch_cc_batch,
#  sound_to_pitch_shs_batch, sound_to_pitch_spinet_batch, sound_to_formant_batch,
#  sound_to_intensity_batch, sound_extract_and_pitch, sound_extract_and_formant,
#  sound_load_window)
#
# All *_batch functions return a plain list() of R6 objects (via lapply over
# xptrs), not a data.frame or bespoke collection object -- verified directly
# against R/batch-ops.R before writing these assertions.

make_test_sounds <- function(n = 2) {
  freqs <- c(150, 200, 250)[seq_len(n)]
  lapply(freqs, function(f) generate_sine_wave(f, 0.5, sampling_rate = 16000))
}

test_that("sound_concatenate_all concatenates a list of Sounds", {
  sounds <- make_test_sounds(2)
  combined <- sound_concatenate_all(sounds)

  expect_s3_class(combined, "Sound")
  expect_true(combined$is_valid())
  # Concatenating two 0.5s sounds should give ~1.0s (no overlap)
  expect_equal(combined$get_total_duration(), 1.0, tolerance = 1e-6)
})

test_that("sound_concatenate_all supports overlap and return_r6 = FALSE", {
  sounds <- make_test_sounds(2)
  combined_overlap <- sound_concatenate_all(sounds, overlap = 0.1)
  expect_s3_class(combined_overlap, "Sound")
  expect_equal(combined_overlap$get_total_duration(), 0.9, tolerance = 1e-6)

  ptr <- sound_concatenate_all(sounds, return_r6 = FALSE)
  expect_true(inherits(ptr, "externalptr"))
})

test_that("sound_concatenate_all validates its arguments", {
  expect_error(sound_concatenate_all(list()), "Cannot concatenate empty list")
  expect_error(sound_concatenate_all(list("not a sound")),
               "sounds must be a list of Sound objects or external pointers")
})

test_that("sound_to_pitch_batch, sound_to_pitch_ac_batch, sound_to_pitch_cc_batch return per-sound Pitch results", {
  sounds <- make_test_sounds(2)

  pitches <- sound_to_pitch_batch(sounds)
  expect_type(pitches, "list")
  expect_length(pitches, 2)
  expect_s3_class(pitches[[1]], "Pitch")
  expect_true(pitches[[1]]$is_valid())
  expect_gte(pitches[[1]]$get_number_of_frames(), 1)

  pitches_ac <- sound_to_pitch_ac_batch(sounds, very_accurate = TRUE)
  expect_length(pitches_ac, 2)
  expect_s3_class(pitches_ac[[2]], "Pitch")
  expect_true(pitches_ac[[2]]$is_valid())

  pitches_cc <- sound_to_pitch_cc_batch(sounds)
  expect_length(pitches_cc, 2)
  expect_s3_class(pitches_cc[[1]], "Pitch")
  expect_true(pitches_cc[[1]]$is_valid())

  # return_r6 = FALSE gives raw externalptrs
  raw_ptrs <- sound_to_pitch_batch(sounds, return_r6 = FALSE)
  expect_length(raw_ptrs, 2)
  expect_true(all(vapply(raw_ptrs, inherits, logical(1), what = "externalptr")))
})

test_that("sound_to_pitch_shs_batch and sound_to_pitch_spinet_batch return per-sound Pitch results", {
  sounds <- make_test_sounds(2)

  pitches_shs <- sound_to_pitch_shs_batch(sounds, time_step = 0.01, pitch_floor = 50,
                                           max_frequency = 1250, pitch_ceiling = 500)
  expect_length(pitches_shs, 2)
  expect_s3_class(pitches_shs[[1]], "Pitch")
  expect_true(pitches_shs[[1]]$is_valid())

  # The vendored Praat SPINET path intermittently fails with "all amplitudes
  # equal to zero" (see tests/testthat/test-sound-shs-spinet-pitch.R). A
  # single retry of the whole batch call reliably avoids double-failures.
  pitches_spinet <- tryCatch(
    sound_to_pitch_spinet_batch(sounds),
    error = function(e) sound_to_pitch_spinet_batch(sounds)
  )
  expect_length(pitches_spinet, 2)
  expect_s3_class(pitches_spinet[[1]], "Pitch")
  expect_true(pitches_spinet[[1]]$is_valid())
  expect_s3_class(pitches_spinet[[2]], "Pitch")
  expect_true(pitches_spinet[[2]]$is_valid())
})

test_that("sound_to_formant_batch and sound_to_intensity_batch return per-sound results", {
  sounds <- make_test_sounds(3)

  formants <- sound_to_formant_batch(sounds)
  expect_length(formants, 3)
  expect_s3_class(formants[[1]], "Formant")
  expect_true(formants[[1]]$is_valid())
  expect_gte(formants[[1]]$get_number_of_frames(), 1)

  intensities <- sound_to_intensity_batch(sounds)
  expect_length(intensities, 3)
  expect_s3_class(intensities[[1]], "Intensity")
  expect_true(intensities[[1]]$is_valid())
  expect_gte(intensities[[1]]$get_number_of_frames(), 1)

  # return_r6 = FALSE gives raw externalptrs for both
  formant_ptrs <- sound_to_formant_batch(sounds, return_r6 = FALSE)
  expect_true(all(vapply(formant_ptrs, inherits, logical(1), what = "externalptr")))
  intensity_ptrs <- sound_to_intensity_batch(sounds, return_r6 = FALSE)
  expect_true(all(vapply(intensity_ptrs, inherits, logical(1), what = "externalptr")))
})

test_that("sound_extract_and_pitch and sound_extract_and_formant work on a single Sound", {
  sound <- generate_sine_wave(150, 2.0, sampling_rate = 16000)
  from_times <- c(0.2, 1.0)
  to_times <- c(0.6, 1.4)

  pitches <- sound_extract_and_pitch(sound, from_times, to_times)
  expect_type(pitches, "list")
  expect_length(pitches, 2)
  expect_s3_class(pitches[[1]], "Pitch")
  expect_true(pitches[[1]]$is_valid())

  formants <- sound_extract_and_formant(sound, from_times, to_times)
  expect_length(formants, 2)
  expect_s3_class(formants[[1]], "Formant")
  expect_true(formants[[1]]$is_valid())
})

test_that("sound_load_window loads a windowed segment from a WAV file", {
  sound <- generate_sine_wave(220, 2.0, sampling_rate = 16000, amplitude = 0.5)
  path <- tempfile(fileext = ".wav")
  sound$save(path)
  on.exit(unlink(path))

  window <- sound_load_window(path, start = 0.5, end = 0.6)
  expect_s3_class(window, "Sound")
  expect_true(window$is_valid())
  expect_equal(window$get_total_duration(), 0.1, tolerance = 1e-3)
  # Default preserve_times = FALSE shifts window to start at 0
  expect_equal(window$get_start_time(), 0, tolerance = 1e-6)

  window_resampled <- sound_load_window(path, start = 0.5, end = 0.6, resample_to = 8000)
  expect_s3_class(window_resampled, "Sound")
  expect_equal(window_resampled$get_sampling_frequency(), 8000, tolerance = 1e-6)

  window_timed <- sound_load_window(path, start = 0.5, end = 0.6, preserve_times = TRUE)
  expect_equal(window_timed$get_start_time(), 0.5, tolerance = 1e-3)
})

test_that("sound_load_window validates its arguments", {
  sound <- generate_sine_wave(220, 1.0, sampling_rate = 16000, amplitude = 0.5)
  path <- tempfile(fileext = ".wav")
  sound$save(path)
  on.exit(unlink(path))

  expect_error(sound_load_window(123, 0, 0.5), "path must be a single character string")
  expect_error(sound_load_window("/no/such/file.wav", 0, 0.5), "File not found")
  expect_error(sound_load_window(path, -1, 0.5), "start must be a non-negative number")
  expect_error(sound_load_window(path, 0, "x"), "end must be a number")
  expect_error(sound_load_window(path, 0.5, 0.2), "end must be greater than start")
  expect_error(sound_load_window(path, 0, 0.5, resample_to = -100), "resample_to must be a positive number or NULL")
  expect_error(sound_load_window(path, 0, 0.5, preserve_times = "yes"), "preserve_times must be TRUE or FALSE")
})
