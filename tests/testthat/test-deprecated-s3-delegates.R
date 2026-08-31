# test-deprecated-s3-delegates.R - Tests for the deprecated-but-still-shipped
# S3 delegate functions in R/pitch.R, R/intensity.R, R/sound.R. These are
# thin `sound$method()`/`pitch$method()` wrappers around the live R6 API
# (unlike the deeper legacy S3 reimplementations in R/formant.R), so are
# cheap and low-risk to cover directly.

tone_sound <- function(freq = 150, dur = 0.5, sr = 16000) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)
}

# --- R/pitch.R ----------------------------------------------------------------

test_that("extract_pitch()/get_*_pitch() delegate to the R6 Pitch API", {
  sound <- tone_sound()
  expect_warning(pitch <- extract_pitch(sound, pitch_floor = 75, pitch_ceiling = 600), "deprecated")
  expect_s3_class(pitch, "Pitch")

  expect_warning(val <- get_pitch_at_time(pitch, 0.25, unit = "Hz"), "deprecated")
  expect_equal(val, pitch$get_value_at_time(0.25, "hertz"), tolerance = sqrt(.Machine$double.eps))

  expect_warning(mean_val <- get_mean_pitch(pitch), "deprecated")
  expect_equal(mean_val, pitch$get_mean(0, 0, "hertz"), tolerance = sqrt(.Machine$double.eps))

  expect_warning(min_val <- get_min_pitch(pitch, time_range = c(0.1, 0.3)), "deprecated")
  expect_equal(min_val, pitch$get_minimum(0.1, 0.3, "hertz", interpolate = FALSE), tolerance = sqrt(.Machine$double.eps))

  expect_warning(max_val <- get_max_pitch(pitch), "deprecated")
  expect_equal(max_val, pitch$get_maximum(0, 0, "hertz", interpolate = FALSE), tolerance = sqrt(.Machine$double.eps))
})

# --- R/intensity.R --------------------------------------------------------------

test_that("extract_intensity()/get_*_intensity() delegate to the R6 Intensity API", {
  sound <- tone_sound()
  expect_warning(intensity <- extract_intensity(sound), "deprecated")
  expect_s3_class(intensity, "Intensity")

  expect_warning(val <- get_intensity_at_time(intensity, 0.25), "deprecated")
  expect_equal(val, intensity$get_value_at_time(0.25), tolerance = sqrt(.Machine$double.eps))

  expect_warning(mean_val <- get_mean_intensity(intensity), "deprecated")
  expect_equal(mean_val, intensity$get_mean(0, 0), tolerance = sqrt(.Machine$double.eps))

  expect_warning(min_val <- get_min_intensity(intensity, time_range = c(0.1, 0.3)), "deprecated")
  expect_equal(min_val, intensity$get_minimum(0.1, 0.3, interpolation = "none"), tolerance = sqrt(.Machine$double.eps))

  expect_warning(max_val <- get_max_intensity(intensity), "deprecated")
  expect_equal(max_val, intensity$get_maximum(0, 0, interpolation = "none"), tolerance = sqrt(.Machine$double.eps))

  expect_warning(sd_val <- get_sd_intensity(intensity), "deprecated")
  expect_equal(sd_val, intensity$get_standard_deviation(0, 0), tolerance = sqrt(.Machine$double.eps))
})

# --- R/sound.R --------------------------------------------------------------------

test_that("create_sound()/get_*() delegate to the R6 Sound API", {
  expect_warning(sound <- create_sound(c(-1, 0, 1), sampling_rate = 8000), "deprecated")
  expect_s3_class(sound, "Sound")

  expect_warning(dur <- get_duration(sound), "deprecated")
  expect_equal(dur, sound$get_duration(), tolerance = sqrt(.Machine$double.eps))

  expect_warning(sr <- get_sampling_rate(sound), "deprecated")
  expect_equal(sr, sound$get_sampling_frequency(), tolerance = sqrt(.Machine$double.eps))

  expect_warning(nch <- get_n_channels(sound), "deprecated")
  expect_equal(nch, sound$get_number_of_channels(), tolerance = sqrt(.Machine$double.eps))

  expect_warning(ns <- get_n_samples(sound), "deprecated")
  expect_equal(ns, sound$get_number_of_samples(), tolerance = sqrt(.Machine$double.eps))
})

test_that("read_sound() delegates to Sound$new() and supports channel extraction", {
  tmp <- tempfile(fileext = ".wav")
  tone_sound()$save(tmp)
  on.exit(unlink(tmp))

  expect_warning(sound <- read_sound(tmp), "deprecated")
  expect_s3_class(sound, "Sound")
  expect_identical(sound$get_number_of_channels(), 1L)
})
