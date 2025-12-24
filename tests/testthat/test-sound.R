# test-sound.R - Tests for sound object creation and properties
#
# These tests follow TDD principles (written BEFORE implementation)
# They define the expected behavior of sound object functions
#
# NOTE: These tests are for the DEPRECATED S3 API.
# The S3 API (create_sound, read_sound returning praat_sound S3 objects) is deprecated.
# Tests are skipped. Use R6 API: Sound$new(), Sound$from_values(), etc.

skip("S3 API deprecated - use R6 API instead (Sound$new(), Sound$from_values())")

test_that("create_sound() creates valid praat_sound object with correct attributes", {
  # Create a simple sound object from numeric vector
  values <- c(0.1, 0.2, -0.1, -0.2, 0.0)
  sampling_rate <- 1000

  sound <- create_sound(values, sampling_rate = sampling_rate)

  # Check object class
  expect_s3_class(sound, "Sound")
  expect_type(sound, "list")

  # Check required fields exist
  expect_true("values" %in% names(sound))
  expect_true("time" %in% names(sound))
  expect_true("sampling_rate" %in% names(sound))
  expect_true("n_samples" %in% names(sound))
  expect_true("n_channels" %in% names(sound))
  expect_true("duration" %in% names(sound))
  expect_true("start_time" %in% names(sound))
  expect_true("end_time" %in% names(sound))

  # Check values are correct
  expect_equal(sound$values, values)
  expect_equal(sound$sampling_rate, sampling_rate)
  expect_equal(sound$n_samples, length(values))
  expect_equal(sound$n_channels, 1)  # Default mono

  # Check computed duration
  expected_duration <- length(values) / sampling_rate
  expect_equal(sound$duration, expected_duration, tolerance = 1e-10)

  # Check time vector
  expect_length(sound$time, length(values))
  expect_equal(sound$time[1], 0.0, tolerance = 1e-10)
  expect_equal(sound$time[length(sound$time)],
               expected_duration - 1/sampling_rate, tolerance = 1e-10)
})

test_that("create_sound() handles custom start_time", {
  values <- c(0.1, 0.2, 0.3)
  sampling_rate <- 1000
  start_time <- 5.0

  sound <- create_sound(values, sampling_rate = sampling_rate,
                       start_time = start_time)

  expect_equal(sound$start_time, start_time)
  expect_equal(sound$time[1], start_time, tolerance = 1e-10)
  expect_equal(sound$end_time, start_time + sound$duration, tolerance = 1e-10)
})

test_that("create_sound() validates input parameters", {
  # Empty values should error
  expect_error(create_sound(numeric(0), sampling_rate = 1000),
               "empty")

  # Non-positive sampling rate should error
  expect_error(create_sound(c(0.1), sampling_rate = 0),
               "sampling rate")
  expect_error(create_sound(c(0.1), sampling_rate = -100),
               "sampling rate")

  # Non-numeric values should error
  expect_error(create_sound("not numeric", sampling_rate = 1000))
})

test_that("read_sound() loads WAV file and extracts correct metadata", {
  # Test with sine wave fixture
  wav_path <- test_path("fixtures/sine_440hz.wav")
  skip_if_not(file.exists(wav_path), "Test fixture not found")

  sound <- read_sound(wav_path)

  # Check object class
  expect_s3_class(sound, "Sound")

  # Check expected properties for 1 second 440 Hz sine wave at 44100 Hz
  expect_equal(sound$sampling_rate, 44100)
  expect_equal(sound$duration, 1.0, tolerance = 1e-6)
  expect_equal(sound$n_samples, 44100)
  expect_equal(sound$n_channels, 1)  # Mono by default

  # Check values are numeric and in valid range
  expect_type(sound$values, "double")
  expect_true(all(sound$values >= -1.0 & sound$values <= 1.0))

  # Check time vector is correct
  expect_length(sound$time, sound$n_samples)
  expect_equal(sound$time[1], 0.0, tolerance = 1e-10)
})

test_that("read_sound() handles channel parameter for stereo files", {
  wav_path <- test_path("fixtures/sine_440hz.wav")
  skip_if_not(file.exists(wav_path), "Test fixture not found")

  # Default should be left channel (0)
  sound_default <- read_sound(wav_path)
  sound_left <- read_sound(wav_path, channel = 0)
  sound_right <- read_sound(wav_path, channel = 1)

  # For mono file, all should be the same
  expect_equal(sound_default$values, sound_left$values)

  # channel parameter should be stored
  expect_equal(sound_left$channel, 0)
})

test_that("read_sound() validates file path", {
  # Non-existent file should error
  expect_error(read_sound("nonexistent.wav"), "not found|does not exist")

  # Invalid file path should error
  expect_error(read_sound(""), "empty")
  expect_error(read_sound(NULL))
})

test_that("read_sound() validates file extension", {
  # Create a temporary non-WAV file
  temp_file <- tempfile(fileext = ".txt")
  writeLines("not a wav", temp_file)
  on.exit(unlink(temp_file))

  expect_error(read_sound(temp_file), "WAV|extension")
})

test_that("get_duration() extracts duration correctly", {
  sound <- create_sound(rep(0, 1000), sampling_rate = 1000)

  duration <- get_duration(sound)

  expect_type(duration, "double")
  expect_equal(duration, 1.0, tolerance = 1e-10)
  expect_length(duration, 1)
})

test_that("get_sampling_rate() extracts sampling rate correctly", {
  sound <- create_sound(rep(0, 100), sampling_rate = 44100)

  sr <- get_sampling_rate(sound)

  expect_type(sr, "double")
  expect_equal(sr, 44100)
  expect_length(sr, 1)
})

test_that("get_n_channels() extracts channel count correctly", {
  sound <- create_sound(rep(0, 100), sampling_rate = 1000)

  n_channels <- get_n_channels(sound)

  expect_type(n_channels, "integer")
  expect_equal(n_channels, 1)  # Default mono
  expect_length(n_channels, 1)
})

test_that("get_n_samples() extracts sample count correctly", {
  values <- rep(0, 12345)
  sound <- create_sound(values, sampling_rate = 1000)

  n_samples <- get_n_samples(sound)

  expect_type(n_samples, "integer")
  expect_equal(n_samples, 12345)
  expect_length(n_samples, 1)
})

test_that("property getters validate input", {
  not_a_sound <- list(foo = "bar")

  expect_error(get_duration(not_a_sound), "praat_sound")
  expect_error(get_sampling_rate(not_a_sound), "praat_sound")
  expect_error(get_n_channels(not_a_sound), "praat_sound")
  expect_error(get_n_samples(not_a_sound), "praat_sound")
})

test_that("is_praat_sound() correctly identifies sound objects", {
  sound <- create_sound(c(0.1, 0.2), sampling_rate = 1000)

  expect_true(is_praat_sound(sound))
  expect_false(is_praat_sound(list()))
  expect_false(is_praat_sound(NULL))
  expect_false(is_praat_sound(data.frame()))
  expect_false(is_praat_sound("not a sound"))
})
