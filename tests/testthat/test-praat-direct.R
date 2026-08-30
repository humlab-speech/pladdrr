# test-praat-direct.R - Tests for R/praat-direct.R (direct XPtr-dispatch API,
# bypasses R6 method dispatch; backs src/praat_direct.cpp)

tone_sound <- function(freq = 150, dur = 0.5, sr = 16000) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)
}

test_that("get_pitch_stats_direct returns full stats and accepts R6 or xptr input", {
  sound <- tone_sound()
  pitch <- sound$to_pitch_cc()

  stats <- get_pitch_stats_direct(pitch)
  expect_named(stats, c("min", "max", "mean", "stdev", "median", "q25", "q75", "count_voiced"))
  expect_gt(stats$count_voiced, 0)

  stats_xptr <- get_pitch_stats_direct(pitch$.xptr)
  expect_equal(stats_xptr$mean, stats$mean)

  expect_error(get_pitch_stats_direct(list()), "Pitch object or external pointer")
})

test_that("get_formants_direct returns F1-F4 and accepts R6 or xptr input", {
  sound <- tone_sound(freq = 220)
  formant <- sound$to_formant_burg()

  f <- get_formants_direct(formant, time = 0.25)
  expect_named(f, c("F1", "F2", "F3", "F4"))

  f_xptr <- get_formants_direct(formant$.xptr, time = 0.25)
  expect_equal(f_xptr, f)

  expect_error(get_formants_direct(list(), time = 0.25), "Formant object or external pointer")
})

test_that("to_pitch_direct returns a usable Pitch xptr", {
  sound <- tone_sound()
  ptr <- to_pitch_direct(sound, pitch_floor = 75, pitch_ceiling = 600)

  expect_type(ptr, "externalptr")
  pitch <- Pitch(.xptr = ptr)
  expect_gt(pitch$get_mean(0, 0, "hertz"), 0)

  ptr2 <- to_pitch_direct(sound$.xptr)
  expect_type(ptr2, "externalptr")

  expect_error(to_pitch_direct(list()), "Sound object or external pointer")
})

test_that("to_pitch_ac_direct and to_pitch_cc_direct accept full voicing parameters", {
  sound <- tone_sound()

  ptr_ac <- to_pitch_ac_direct(sound, pitch_floor = 75, pitch_ceiling = 600,
                                voicing_threshold = 0.45)
  ptr_cc <- to_pitch_cc_direct(sound, pitch_floor = 75, pitch_ceiling = 600,
                                voicing_threshold = 0.45)

  expect_gt(get_pitch_mean_direct(ptr_ac), 0)
  expect_gt(get_pitch_mean_direct(ptr_cc), 0)
})

test_that("to_formant_direct/to_intensity_direct/to_harmonicity_direct return usable xptrs", {
  sound <- tone_sound(freq = 220)

  fptr <- to_formant_direct(sound)
  expect_true(get_formant_value_direct(fptr, 1, 0.25) >= 0 || is.na(get_formant_value_direct(fptr, 1, 0.25)))

  iptr <- to_intensity_direct(sound)
  expect_gt(get_intensity_value_direct(iptr, 0.25), 0)

  hptr <- to_harmonicity_direct(sound)
  expect_type(hptr, "externalptr")
})

test_that("get_pitch_value_direct/get_pitch_quantile_direct/get_pitch_mean_direct/get_pitch_stdev_direct agree with R6", {
  sound <- tone_sound()
  pitch <- sound$to_pitch_cc()

  val_direct <- get_pitch_value_direct(pitch, time = 0.25, unit = "hertz")
  val_r6 <- pitch$get_value_at_time(0.25, "hertz")
  expect_equal(val_direct, val_r6, tolerance = 1e-6)

  q_direct <- get_pitch_quantile_direct(pitch, 0.5)
  expect_true(is.numeric(q_direct))

  mean_direct <- get_pitch_mean_direct(pitch)
  mean_r6 <- pitch$get_mean(0, 0, "hertz")
  expect_equal(mean_direct, mean_r6, tolerance = 1e-6)

  sd_direct <- get_pitch_stdev_direct(pitch)
  expect_true(is.numeric(sd_direct))
})

test_that("to_spectrum_direct and to_ltas_direct produce usable results", {
  sound <- tone_sound()

  spec_ptr <- to_spectrum_direct(sound)
  expect_type(spec_ptr, "externalptr")

  ltas <- to_ltas_direct(sound)
  expect_s3_class(ltas, "Ltas")
})

test_that("to_point_process_direct and to_point_process_from_sound_and_pitch produce usable PointProcess pointers", {
  sound <- tone_sound(dur = 1.0)
  pitch <- sound$to_pitch()

  pp_ptr1 <- to_point_process_direct(sound, pitch_floor = 75, pitch_ceiling = 600)
  expect_type(pp_ptr1, "externalptr")
  expect_gt(pp_get_mean_period_direct(pp_ptr1), 0)

  pp_ptr2 <- to_point_process_from_sound_and_pitch(sound, pitch)
  expect_type(pp_ptr2, "externalptr")
  expect_gte(pp_get_stdev_period_direct(pp_ptr2), 0)
})

test_that("two_pass_adaptive_pitch returns an adaptive-range pitch result", {
  sound <- tone_sound(dur = 1.0)

  result <- two_pass_adaptive_pitch(sound)
  expect_type(result$pitch, "externalptr")
  expect_lt(result$min_pitch, result$max_pitch)

  pitch_refined <- Pitch(.xptr = result$pitch)
  expect_gt(pitch_refined$get_mean(0, 0, "hertz"), 0)
})

test_that("to_pitch_cc_direct rejects invalid input", {
  expect_error(to_pitch_cc_direct("x"), "sound must be a Sound object")
})

test_that("to_spectrogram_direct accepts a Sound via its C++ pointer path", {
  snd <- Sound$create_tone(frequency = 200, duration = 0.2)
  sg <- to_spectrogram_direct(snd, time_step = 0.005, max_frequency = 5000)
  expect_true(inherits(sg, "externalptr"))
})
