# test-sound-stats-functions.R - Tests for R/sound-stats.R
# (sound_mean/min/max/rms/statistics; distinct from Sound$get_rms() etc.)

test_that("sound_mean/min/max/rms work on module Sound objects", {
  snd <- Sound$from_values(c(-1, 0, 1), sampling_rate = 1000)

  expect_equal(sound_mean(snd), 0, tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_min(snd), -1, tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_max(snd), 1, tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_rms(snd), sqrt(mean(c(-1, 0, 1)^2)),
    tolerance = sqrt(.Machine$double.eps))
})

legacy_praat_sound <- function(values, sampling_rate = 8000) {
  n <- length(values)
  structure(
    list(
      values = values,
      time = seq(0, (n - 1) / sampling_rate, length.out = n),
      sampling_rate = sampling_rate,
      n_samples = n,
      duration = n / sampling_rate,
      start_time = 0,
      end_time = n / sampling_rate
    ),
    class = "praat_sound"
  )
}

test_that("sound_mean/min/max/rms work on legacy S3 praat_sound objects", {
  snd <- legacy_praat_sound(c(-1, 0, 0.5, 1))

  expect_equal(sound_mean(snd), mean(snd$values),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_min(snd), min(snd$values),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_max(snd), max(snd$values),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sound_rms(snd), sqrt(mean(snd$values^2)),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("sound_rms approximates 1/sqrt(2) for a full-cycle sine", {
  snd <- generate_sine_wave(frequency = 100, duration = 1,
    sampling_rate = 44100,
                             amplitude = 1.0)
  expect_equal(sound_rms(snd), 1 / sqrt(2), tolerance = 1e-3)
})

test_that("sound_statistics returns all expected fields for a module Sound", {
  snd <- Sound$create_tone(frequency = 150, duration = 0.5,
    sampling_rate = 16000)
  stats <- sound_statistics(snd)

  expect_named(stats, c("mean", "min", "max", "rms", "duration", "n_samples",
                         "sampling_rate"))
  expect_equal(stats$duration, snd$get_duration(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(stats$n_samples, snd$get_number_of_samples(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(stats$sampling_rate, snd$get_sampling_frequency(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(stats$rms, sound_rms(snd), tolerance = sqrt(.Machine$double.eps))
})

test_that(
  "sound_statistics returns all expected fields for a legacy S3 praat_sound", {
  snd <- legacy_praat_sound(sin(2 * pi * 100 * seq(0, 0.2, length.out = 1600)))
  stats <- sound_statistics(snd)

  expect_named(stats, c("mean", "min", "max", "rms", "duration", "n_samples",
                         "sampling_rate"))
  expect_equal(stats$duration, snd$duration,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(stats$n_samples, snd$n_samples,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(stats$sampling_rate, snd$sampling_rate,
    tolerance = sqrt(.Machine$double.eps))
})

test_that("sound_mean etc. reject non-sound input via validate_sound_object", {
  expect_error(sound_mean(list(not = "a sound")))
  expect_error(sound_min(1:5))
})
