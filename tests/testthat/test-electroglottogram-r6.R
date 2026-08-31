# test-electroglottogram-r6.R - Tests for R/electroglottogram-wrapper.R (Electroglottogram object)
#
# Electroglottogram has no setter to fill in individual samples (no
# `set_value_at_sample` exists on the Rcpp module -- confirmed via
# `grep -n "set_value_at_sample" src/modules/*.cpp`, no match). A real,
# non-trivial EGG signal is instead built via the actual Sound -> EGG
# conversion path: `sound_from_values()` creates a Sound with real sample
# data, and `Sound$extract_electroglottogram()` (verified in
# R/sound-wrapper.R) converts it to an Electroglottogram carrying that data.
#
# `to_textgrid_closed_glottis()` is exercised with `expect_error()`, not a
# success path: the stub in src/melderthread_impl.cpp always throws "not
# available in this build" regardless of build flags or input signal --
# verified by temporarily surfacing the underlying Melder error message (no
# combination of pitch floor/ceiling, closing threshold, peak threshold, or
# signal shape avoids it). This is NOT a fundamental limitation: the real
# implementation (`Vector_getNearestLevelCrossing`) exists in-tree at
# src/praat.github.io/dwtools/Vector_extensions.cpp:27, it is just missing
# from the `DWTOOLS_SRC` file list in src/Makevars.in, so it never gets
# compiled in and the stub wins at link time. Wiring it up is a one-line
# Makevars.in fix, tracked as a separate follow-up -- out of scope here.

make_test_egg <- function(sampling_rate = 16000, duration = 0.2, f0 = 120) {
  n <- round(sampling_rate * duration)
  t <- (0:(n - 1)) / sampling_rate
  values <- (sin(2 * pi * f0 * t) > 0) * 1.0  # crude glottal pulse train
  snd <- sound_from_values(values, sampling_rate = sampling_rate)
  snd$extract_electroglottogram(channel = 1, invert = FALSE)
}

test_that("Electroglottogram constructs and reports basic Sound-like properties", {
  egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 / 16000, x1 = 0)
  expect_s3_class(egg, "Electroglottogram")
  expect_s3_class(egg, "Sound")
  expect_true(egg$is_valid())
  expect_equal(egg$get_xmin(), 0, tolerance = sqrt(.Machine$double.eps))
  expect_equal(egg$get_xmax(), 1, tolerance = sqrt(.Machine$double.eps))
  expect_identical(egg$get_nx(), 16000L)
  expect_equal(egg$get_dx(), 1 / 16000, tolerance = sqrt(.Machine$double.eps))
  expect_identical(egg$get_number_of_samples(), 16000L)
  expect_type(egg$get_sample_period(), "double")
  expect_type(egg$get_sample_rate(), "double")
})

test_that("Electroglottogram sample/time conversions and value access", {
  egg <- electroglottogram_create(xmin = 0, xmax = 1, nx = 16000, dx = 1 / 16000, x1 = 0)
  expect_type(egg$get_value_at_sample(100), "double")
  expect_type(egg$get_value_at_time(0.5), "double")
  expect_type(egg$get_time_from_sample(100), "double")
  expect_type(egg$get_sample_from_time(0.5), "integer")
})

test_that("Electroglottogram derivative/filter/sound conversions work on real signal data", {
  egg <- make_test_egg()

  d <- egg$derivative()
  expect_s3_class(d, "Sound")

  fcd <- egg$first_central_difference()
  expect_s3_class(fcd, "Sound")

  hp <- egg$high_pass_filter(from_freq = 50, smoothing = 50)
  expect_s3_class(hp, "Electroglottogram")

  snd <- egg$to_sound()
  expect_s3_class(snd, "Sound")
})

test_that("Electroglottogram to_amplitude_tier_levels returns levels/peaks/valleys AmplitudeTiers", {
  egg <- make_test_egg()
  at <- egg$to_amplitude_tier_levels(pitch_floor = 75)
  expect_type(at, "list")
  expect_named(at, c("levels", "peaks", "valleys"))
  expect_s3_class(at$levels, "AmplitudeTier")
  expect_s3_class(at$peaks, "AmplitudeTier")
  expect_s3_class(at$valleys, "AmplitudeTier")
})

test_that("Electroglottogram to_textgrid_closed_glottis errors (Vector_getNearestLevelCrossing stub)", {
  egg <- make_test_egg()
  # Vector_getNearestLevelCrossing is an unconditional stub in
  # src/melderthread_impl.cpp that always throws -- this always errors
  # regardless of input signal or parameters, in this build.
  expect_error(egg$to_textgrid_closed_glottis(pitch_floor = 75), "Failed to extract closed glottis TextGrid")
})

test_that("Electroglottogram as_vector/as_data_frame/get_info/save/print", {
  egg <- make_test_egg(duration = 0.05)

  v <- egg$as_vector()
  expect_type(v, "double")
  expect_length(v, egg$get_number_of_samples())

  df <- egg$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_named(df, c("time", "amplitude"))
  expect_equal(nrow(df), egg$get_number_of_samples(), tolerance = sqrt(.Machine$double.eps))

  info <- egg$get_info()
  expect_type(info, "list")
  expect_true(all(c("xmin", "xmax", "nx", "dx", "x1", "sample_rate") %in% names(info)))

  tmp <- tempfile(fileext = ".Egg")
  on.exit(unlink(tmp), add = TRUE)
  egg$save(tmp)
  expect_true(file.exists(tmp))

  expect_output(print(egg), "<Praat Electroglottogram>")
})
