# test-sound-wrapper-gaps.R - Coverage gap-fill for src/sound_wrappers.cpp and
# src/modules/sound_module.cpp (task-17 of the 2026-08-21 coverage-75-percent
# gapfill plan). Targets Sound R6 methods that existing test-sound-*.R files
# (and the rest of the suite) never exercise directly, per a real covr
# missed-lines run. See .superpowers/sdd/2026-08-21-coverage-75-percent/
# gapfill/task-17-{brief,missed-lines,report}.md for the full mapping.
#
# Dual-implementation note (see MEMORY.md "PowerCepstrum dual-implementation
# trap"): several Sound$ methods (lengthen, deepen_band_modulation, convolve,
# cross_correlate) look redundant with standalone sound_lengthen()/
# sound_deepen_band_modulation()/sounds_convolve()/sounds_cross_correlate()
# in test-sound-operations.R, but those standalone functions call the Rcpp
# *module* methods (mod$sound_lengthen etc.), while Sound$lengthen() etc.
# call a *different* set of plain Rcpp::export functions in
# sound_wrappers.cpp (sound_lengthen_ola, sound_autocorrelate,
# sounds_convolve_export, sounds_cross_correlate_export,
# sound_deepen_band_mod). Testing the standalone entrypoint does not cover
# the R6 method's code path, and vice versa.

tone <- function(freq = 220, dur = 0.5, sr = 16000, amp = 0.8) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)
}

# ============================================================================
# get_value_at_time() - interpolation branches + error paths
# (.sound_get_value_at_time in sound_wrappers.cpp)
# ============================================================================

test_that("Sound$get_value_at_time supports all interpolation types", {
  s <- tone()
  for (interp in c("nearest", "linear", "cubic", "sinc70", "sinc700")) {
    val <- s$get_value_at_time(0.1, 1, interp)
    expect_type(val, "double")
    expect_length(val, 1)
  }
})

test_that("Sound$get_value_at_time rejects an invalid interpolation type", {
  s <- tone()
  expect_error(s$get_value_at_time(0.1, 1, "bogus"), "Invalid interpolation type")
})

test_that("Sound$get_value_at_time rejects an out-of-range channel", {
  s <- tone()
  expect_error(s$get_value_at_time(0.1, 5, "linear"), "Invalid channel")
})

test_that("Sound$get_value_at_time returns NA for a time outside the sound's domain", {
  s <- tone()
  expect_true(is.na(s$get_value_at_time(1000, 1, "linear")))
})

# ============================================================================
# get_rms/get_energy/get_power - explicit time ranges
# (.sound_get_rms / .sound_get_energy / .sound_get_power, plain exports)
# ============================================================================

test_that("Sound$get_rms/get_energy/get_power accept an explicit time range", {
  s <- tone(dur = 1.0)
  expect_type(s$get_rms(0.1, 0.3), "double")
  expect_type(s$get_energy(0.1, 0.3), "double")
  expect_type(s$get_power(0.1, 0.3), "double")
  # 0,0 sentinel means "whole sound" - both call forms should be finite and equal
  expect_equal(s$get_rms(), s$get_rms(0, 0))
})

# ============================================================================
# get_minimum/get_maximum - all peak-interpolation branches
# get_mean, get_intensity_db (module methods via .self$.cpp$)
# ============================================================================

test_that("Sound$get_minimum/get_maximum support all peak interpolation types", {
  s <- tone()
  for (interp in c("none", "parabolic", "cubic", "sinc70", "sinc700")) {
    expect_type(s$get_minimum(0, 0, 1, interp), "double")
    expect_type(s$get_maximum(0, 0, 1, interp), "double")
  }
})

test_that("Sound$get_mean and get_intensity_db return finite doubles", {
  s <- tone()
  expect_type(s$get_mean(0, 0, 1), "double")
  db <- s$get_intensity_db()
  expect_type(db, "double")
  expect_true(is.finite(db))
})

# ============================================================================
# get_zcr_windows / extract_channel / get_values channel validation
# ============================================================================

test_that("Sound$get_zcr_windows returns a zero-crossing count per window", {
  s <- tone(dur = 1.0)
  zcr <- s$get_zcr_windows(c(0, 0.2), c(0.1, 0.3))
  expect_type(zcr, "double")
  expect_length(zcr, 2)
})

test_that("Sound$extract_channel extracts a single-channel Sound", {
  s <- tone()
  ch <- s$extract_channel(1)
  expect_s3_class(ch, "Sound")
  expect_equal(ch$get_number_of_channels(), 1)
})

test_that("Sound$extract_channel rejects an out-of-range channel", {
  s <- tone()
  expect_error(s$extract_channel(5), "[Cc]hannel")
})

test_that("Sound$get_values rejects an out-of-range channel", {
  s <- tone()
  expect_error(s$get_values(5), "[Cc]hannel")
})

# ============================================================================
# scale_intensity (.sound_scale_intensity)
# ============================================================================

test_that("Sound$scale_intensity mutates intensity in place and returns self invisibly", {
  s <- tone()
  ret <- withVisible(s$scale_intensity(70))
  expect_false(ret$visible)
  expect_equal(s$get_intensity_db(), 70, tolerance = 1e-6)
})

# ============================================================================
# convert_to_stereo - both branches (mono -> stereo, and already-stereo copy)
# ============================================================================

test_that("Sound$convert_to_stereo duplicates a mono channel", {
  s <- tone()
  st <- s$convert_to_stereo()
  expect_s3_class(st, "Sound")
  expect_equal(st$get_number_of_channels(), 2)
})

test_that("Sound$convert_to_stereo on an already-stereo sound warns and copies", {
  s <- tone()
  st <- s$convert_to_stereo()
  expect_warning(st2 <- st$convert_to_stereo(), "already multi-channel")
  expect_s3_class(st2, "Sound")
  expect_equal(st2$get_number_of_channels(), 2)
})

# ============================================================================
# concatenate (.sound_concatenate - distinct from concatenate_sounds/
# sound_concatenate_all, and from the mod$sound_lengthen-style dual paths)
# ============================================================================

test_that("Sound$concatenate joins two sounds end to end", {
  s1 <- tone(freq = 220, dur = 0.3)
  s2 <- tone(freq = 330, dur = 0.2)
  joined <- s1$concatenate(s2)
  expect_s3_class(joined, "Sound")
  expect_equal(joined$get_duration(), s1$get_duration() + s2$get_duration(),
               tolerance = 1e-6)
})

test_that("Sound$concatenate rejects a non-Sound argument", {
  s <- tone()
  expect_error(s$concatenate("not a sound"), "must be a Sound object")
})

# ============================================================================
# lengthen / autocorrelate / convolve / cross_correlate / deepen_band_modulation
# (R6 methods - dual-implementation gap vs. the standalone functions already
# covered in test-sound-operations.R; see file header)
# ============================================================================

test_that("Sound$lengthen time-stretches via the R6 method path", {
  s <- tone(dur = 0.5)
  longer <- s$lengthen(fmin = 75, fmax = 600, factor = 1.5)
  expect_s3_class(longer, "Sound")
  expect_gt(longer$get_duration(), s$get_duration())
})

test_that("Sound$autocorrelate returns a Sound via the R6 method path", {
  s <- tone()
  ac <- s$autocorrelate()
  expect_s3_class(ac, "Sound")
})

test_that("Sound$convolve returns a Sound via the R6 method path", {
  s1 <- tone(freq = 220)
  s2 <- tone(freq = 330)
  cv <- s1$convolve(s2)
  expect_s3_class(cv, "Sound")
})

test_that("Sound$cross_correlate returns a Sound via the R6 method path", {
  s1 <- tone(freq = 220)
  s2 <- tone(freq = 330)
  xc <- s1$cross_correlate(s2)
  expect_s3_class(xc, "Sound")
})

test_that("Sound$deepen_band_modulation returns a Sound via the R6 method path", {
  s <- tone()
  db <- s$deepen_band_modulation()
  expect_s3_class(db, "Sound")
  expect_equal(db$get_duration(), s$get_duration(), tolerance = 1e-6)
})

# ============================================================================
# change_speaker / change_speaker_with_pitch / filter_by_formant(_noscale)
# ============================================================================

test_that("Sound$change_speaker returns a modified Sound", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  cs <- s$change_speaker()
  expect_s3_class(cs, "Sound")
})

test_that("Sound$change_speaker_with_pitch accepts a pre-computed Pitch object", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  pitch <- s$to_pitch()
  csp <- s$change_speaker_with_pitch(pitch)
  expect_s3_class(csp, "Sound")
})

test_that("Sound$filter_by_formant and filter_by_formant_noscale filter using a Formant object", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  frm <- s$to_formant_burg()
  filtered <- s$filter_by_formant(frm)
  expect_s3_class(filtered, "Sound")
  filtered_noscale <- s$filter_by_formant_noscale(frm)
  expect_s3_class(filtered_noscale, "Sound")
})

# ============================================================================
# to_harmonicity_gne / to_ltas_pitch_corrected / to_formant_robust
# ============================================================================

test_that("Sound$to_harmonicity_gne returns a Matrix-like GNE result", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  gne <- s$to_harmonicity_gne()
  expect_s3_class(gne, "Matrix")
})

test_that("Sound$to_ltas_pitch_corrected returns an Ltas object", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  ltas <- s$to_ltas_pitch_corrected()
  expect_s3_class(ltas, "Ltas")
})

test_that("Sound$to_formant_robust returns a Formant object", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  fr <- s$to_formant_robust()
  expect_s3_class(fr, "Formant")
})

# ============================================================================
# pitch_to_pointprocess_peaks / to_point_process_extrema/zeros/periodic_peaks
# / to_pointprocess_periodic_cc / to_pointprocess_periodic_peaks
# ============================================================================

test_that("Sound$pitch_to_pointprocess_peaks builds a PointProcess from a Pitch", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  pitch <- s$to_pitch()
  pp <- s$pitch_to_pointprocess_peaks(pitch)
  expect_s3_class(pp, "PointProcess")
})

test_that("Sound$pitch_to_pointprocess_peaks rejects a non-Pitch argument", {
  s <- tone()
  expect_error(s$pitch_to_pointprocess_peaks("not a pitch"), "Pitch object")
})

test_that("Sound$to_point_process_extrema supports all interpolation types", {
  s <- tone()
  for (interp in c("None", "Parabolic", "Cubic", "Sinc70", "Sinc700")) {
    pp <- s$to_point_process_extrema(interpolation = interp)
    expect_s3_class(pp, "PointProcess")
  }
})

test_that("Sound$to_point_process_zeros builds a PointProcess from zero crossings", {
  s <- tone()
  pp <- s$to_point_process_zeros()
  expect_s3_class(pp, "PointProcess")
})

test_that("Sound$to_point_process_periodic_peaks builds a PointProcess", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  pp <- s$to_point_process_periodic_peaks()
  expect_s3_class(pp, "PointProcess")
})

test_that("Sound$to_pointprocess_periodic_cc (back-compat alias) builds a PointProcess", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  expect_warning(
    pp <- s$to_pointprocess_periodic_cc(time_step = 0.01),
    "not used by"
  )
  expect_s3_class(pp, "PointProcess")
})

test_that("Sound$to_pointprocess_periodic_peaks (back-compat alias) builds a PointProcess", {
  s <- generate_sine_wave(frequency = 150, duration = 0.5, sampling_rate = 16000,
                           amplitude = 0.8)
  pp <- s$to_pointprocess_periodic_peaks()
  expect_s3_class(pp, "PointProcess")
})

# ============================================================================
# to_cepstrum_bw / to_lpc_auto / to_lpc_covariance / to_lpc_marple
# ============================================================================

test_that("Sound$to_cepstrum_bw returns a Cepstrum object", {
  s <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                           amplitude = 0.8)
  cbw <- s$to_cepstrum_bw()
  expect_s3_class(cbw, "Cepstrum")
})

test_that("Sound$to_lpc_auto/to_lpc_covariance/to_lpc_marple all return LPC objects", {
  s <- generate_sine_wave(frequency = 150, duration = 0.3, sampling_rate = 16000,
                           amplitude = 0.8)
  expect_s3_class(s$to_lpc_auto(), "LPC")
  expect_s3_class(s$to_lpc_covariance(), "LPC")
  expect_s3_class(s$to_lpc_marple(), "LPC")
})

# ============================================================================
# save() - format branches + failure path
# ============================================================================

test_that("Sound$save writes every supported audio format", {
  s <- tone(dur = 0.1)
  for (fmt in c("AIFF", "AIFC", "WAV", "NEXT", "SUN", "NIST")) {
    f <- tempfile(fileext = ".snd")
    on.exit(unlink(f), add = TRUE)
    s$save(f, format = fmt)
    expect_true(file.exists(f))
    expect_gt(file.info(f)$size, 0)
  }
})

test_that("Sound$save errors when the target directory does not exist", {
  s <- tone(dur = 0.1)
  expect_error(s$save("/nonexistent_dir_xyz_pladdrr/out.wav", format = "WAV"),
               "Failed to save")
})

# ============================================================================
# Constructor error paths (Sound(), .sound_create_from_values,
# .sound_read_from_file_native)
# ============================================================================

test_that("Sound$new errors clearly for a nonexistent file", {
  expect_error(Sound$new("/nonexistent/path/does-not-exist.wav"), "not found")
})

test_that("Sound$new errors for an existing file the native reader can't parse", {
  bad_file <- tempfile(fileext = ".wav")
  writeLines("not a real wav file", bad_file)
  on.exit(unlink(bad_file), add = TRUE)
  # Exercises sound_read_from_file_native()'s catch block; falls through to
  # the av-package fallback (or its "not installed" message) if native
  # reading fails, so either failure message is acceptable evidence the
  # native-reader error path ran.
  expect_error(Sound$new(bad_file))
})

test_that("Sound$from_values rejects empty values", {
  expect_error(Sound$from_values(numeric(0), sampling_rate = 1000),
               "empty")
})

test_that("Sound$from_values rejects a non-positive sampling rate", {
  expect_error(Sound$from_values(c(1, 2, 3), sampling_rate = -100),
               "positive")
})

# NOT a test: sound_create_from_values()'s guard is `sampling_rate <= 0.0`
# (sound_wrappers.cpp), and IEEE 754 comparisons against NaN are always
# false, so Sound$from_values(values, sampling_rate = NaN) slips past the
# check, computes duration = n_samples / NaN, and segfaults inside
# Sound_createSimple() -- reproduced live during this task, not simulated.
# This is a real memory-safety bug, not a graceful-error path, so per the
# "don't paper over defects" instruction it's flagged here deliberately
# rather than encoded as expect_error(): executing it would crash the R
# process running the test suite (and covr/CI with it), not just fail one
# test. Needs a `!is.finite(sampling_rate)` guard alongside the existing
# `<= 0.0` check in sound_create_from_values(); left unfixed (out of scope
# for a coverage-only task) and unexercised here on purpose.

test_that("Sound$to_pitch surfaces a clear error for a too-short sound", {
  # Exercises RSound::to_pitch_ptr's catch(MelderError) block in
  # sound_module.cpp: Sound_to_Pitch() needs a minimum analysis window, and a
  # 1 ms sound can't provide one.
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(s_short$to_pitch(), "Failed to create Pitch")
})

# ============================================================================
# Batch helpers: length-mismatch validation + failure propagation
# (sound_extract_and_pitch_batch / sound_extract_and_formant_batch /
# sound_to_pitch_batch in sound_wrappers.cpp)
# ============================================================================

test_that("sound_extract_and_pitch errors when from_times/to_times lengths differ", {
  s <- generate_sine_wave(frequency = 150, duration = 1.0, sampling_rate = 16000,
                           amplitude = 0.8)
  expect_error(sound_extract_and_pitch(s, c(0.1, 0.5), c(0.3)), "same length")
})

test_that("sound_extract_and_formant errors when from_times/to_times lengths differ", {
  s <- generate_sine_wave(frequency = 150, duration = 1.0, sampling_rate = 16000,
                           amplitude = 0.8)
  expect_error(sound_extract_and_formant(s, c(0.1, 0.5), c(0.3)), "same length")
})

test_that("sound_to_pitch_batch propagates a Pitch-analysis failure for a too-short sound", {
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(sound_to_pitch_batch(list(s_short)), "Failed to extract pitch")
})

# ============================================================================
# More RSound::to_X_ptr catch(MelderError) blocks in sound_module.cpp,
# reached the same way as to_pitch()'s above: a 1 ms sound can't satisfy the
# minimum analysis-window requirement these Praat routines impose.
# ============================================================================

test_that("Sound$to_intensity surfaces a clear error for a too-short sound", {
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(s_short$to_intensity(), "Failed to create Intensity")
})

test_that("Sound$to_harmonicity_cc surfaces a clear error for a too-short sound", {
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(s_short$to_harmonicity_cc(), "Failed to create Harmonicity")
})

test_that("Sound$to_spectrogram surfaces a clear error for a too-short sound", {
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(s_short$to_spectrogram(), "Failed to create Spectrogram")
})

test_that("Sound$to_point_process_periodic_cc surfaces a clear error for a too-short sound", {
  s_short <- Sound$create_tone(frequency = 220, duration = 0.001, sampling_rate = 8000)
  expect_error(s_short$to_point_process_periodic_cc(), "Failed to create PointProcess")
})

# ============================================================================
# Sound$create_pure_tone() / Sound$create_tone_complex() - entirely untested
# factory functions (sound_create_pure_tone / sound_create_tone_complex in
# sound_wrappers.cpp), including their catch(MelderError) paths.
# ============================================================================

test_that("Sound$create_pure_tone creates a fade-enveloped tone", {
  s <- Sound$create_pure_tone(frequency = 440, duration = 0.5, sampling_rate = 16000,
                               fade_in_duration = 0.05, fade_out_duration = 0.05)
  expect_s3_class(s, "Sound")
  expect_equal(s$get_duration(), 0.5, tolerance = 1e-6)
  # Fade-in means the very first sample should be much quieter than the peak.
  vals <- s$get_values()
  expect_true(abs(vals[1]) < max(abs(vals)) * 0.1)
})

test_that("Sound$create_pure_tone supports multiple channels", {
  s <- Sound$create_pure_tone(frequency = 440, duration = 0.2, sampling_rate = 16000,
                               channels = 2L)
  expect_equal(s$get_number_of_channels(), 2)
})

test_that("Sound$create_pure_tone surfaces a clear error for zero channels", {
  expect_error(Sound$create_pure_tone(frequency = 440, duration = 0.2, channels = 0L),
               "Failed to create pure tone")
})

test_that("Sound$create_tone_complex builds a harmonic series", {
  s <- Sound$create_tone_complex(frequency_step = 100, duration = 0.3, sampling_rate = 16000,
                                  number_of_components = 5L)
  expect_s3_class(s, "Sound")
  expect_equal(s$get_duration(), 0.3, tolerance = 1e-6)
})

test_that("Sound$create_tone_complex supports cosine phase", {
  s <- Sound$create_tone_complex(frequency_step = 200, duration = 0.2, sampling_rate = 16000,
                                  phase = "cosine")
  expect_s3_class(s, "Sound")
})

test_that("Sound$create_tone_complex surfaces a clear error when ceiling is below first_frequency", {
  expect_error(
    sound_create_tone_complex(frequency_step = 100, first_frequency = 5000, ceiling = 100,
                               duration = 0.2),
    "Failed to create tone complex"
  )
})
