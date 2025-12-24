# test-s3-methods.R - Tests for S3 methods (print, summary, as.data.frame)
#
# These tests verify that S3 methods provide appropriate output
#
# NOTE: These tests are for the DEPRECATED S3 API.
# The S3 API (print.praat_sound, summary.praat_sound, etc.) is deprecated.
# Tests are skipped. Use R6 API: sound$print(), sound$as_data_frame(), etc.

skip("S3 API deprecated - use R6 API instead (sound$print(), sound$as_data_frame())")

test_that("print.praat_sound() produces informative console output", {
  sound <- create_sound(rep(0.5, 1000), sampling_rate = 10000)

  # Capture print output
  output <- capture.output(print(sound))

  # Should return multiple lines
  expect_gt(length(output), 0)

  # Output should be character vector
  expect_type(output, "character")

  # Should mention key information (not testing exact format)
  output_text <- paste(output, collapse = " ")
  expect_match(output_text, "praat_sound|Sound", ignore.case = TRUE)
  expect_match(output_text, "duration|Duration", ignore.case = TRUE)
  expect_match(output_text, "sampling|rate|Sampling|Rate", ignore.case = TRUE)
  expect_match(output_text, "samples?|Samples?", ignore.case = TRUE)
})

test_that("print.praat_sound() displays correct values", {
  sound <- create_sound(rep(0, 12345), sampling_rate = 22050)

  output <- capture.output(print(sound))
  output_text <- paste(output, collapse = " ")

  # Check numeric values appear
  expect_match(output_text, "22050")  # Sampling rate
  expect_match(output_text, "12345")  # Number of samples
  # Duration should be 12345/22050 ≈ 0.56
  expect_match(output_text, "0\\.5[0-9]")  # Duration
})

test_that("print.praat_sound() handles different sound lengths", {
  # Very short sound
  sound_short <- create_sound(c(0.1, 0.2), sampling_rate = 1000)
  output_short <- capture.output(print(sound_short))
  expect_gt(length(output_short), 0)

  # Long sound
  sound_long <- create_sound(rep(0, 100000), sampling_rate = 44100)
  output_long <- capture.output(print(sound_long))
  expect_gt(length(output_long), 0)
})

test_that("summary.praat_sound() provides statistical summary", {
  sound <- generate_sine_wave(440, 0.5, sampling_rate = 44100)

  # Capture summary output
  output <- capture.output(summary(sound))

  # Should return multiple lines
  expect_gt(length(output), 0)

  output_text <- paste(output, collapse = " ")

  # Should include statistical information
  expect_match(output_text, "mean|Mean", ignore.case = TRUE)
  expect_match(output_text, "min|Min|minimum", ignore.case = TRUE)
  expect_match(output_text, "max|Max|maximum", ignore.case = TRUE)
  expect_match(output_text, "RMS|rms", ignore.case = TRUE)

  # Should include metadata
  expect_match(output_text, "duration|Duration", ignore.case = TRUE)
  expect_match(output_text, "sampling|Sampling", ignore.case = TRUE)
})

test_that("summary.praat_sound() returns invisibly", {
  sound <- create_sound(c(0.1, 0.2), sampling_rate = 1000)

  # summary() should return the object invisibly
  result <- withVisible(summary(sound))
  expect_false(result$visible)
  expect_s3_class(result$value, "Sound")
})

test_that("as.data.frame.praat_sound() converts to data frame correctly", {
  values <- c(0.1, 0.2, -0.1, -0.2, 0.0)
  sound <- create_sound(values, sampling_rate = 1000)

  df <- as.data.frame(sound)

  # Check structure
  expect_s3_class(df, "data.frame")
  expect_equal(nrow(df), length(values))
  expect_equal(ncol(df), 2)  # time and amplitude columns

  # Check column names
  expect_named(df, c("time", "amplitude"))

  # Check column types
  expect_type(df$time, "double")
  expect_type(df$amplitude, "double")

  # Check values
  expect_equal(df$amplitude, values)
  expect_equal(df$time, sound$time)
})

test_that("as.data.frame.praat_sound() preserves time information", {
  sound <- create_sound(c(1, 2, 3), sampling_rate = 1000, start_time = 5.0)

  df <- as.data.frame(sound)

  # Time should start at start_time
  expect_equal(df$time[1], 5.0, tolerance = 1e-10)

  # Time should be evenly spaced
  time_diffs <- diff(df$time)
  expect_equal(time_diffs, rep(1/1000, 2), tolerance = 1e-10)
})

test_that("as.data.frame.praat_sound() handles long sounds", {
  sound <- generate_noise(1.0, sampling_rate = 44100)

  df <- as.data.frame(sound)

  expect_equal(nrow(df), 44100)
  expect_named(df, c("time", "amplitude"))
  expect_false(any(is.na(df$time)))
  expect_false(any(is.na(df$amplitude)))
})

test_that("as.data.frame.praat_sound() handles single sample", {
  sound <- create_sound(c(0.5), sampling_rate = 1000)

  df <- as.data.frame(sound)

  expect_equal(nrow(df), 1)
  expect_equal(df$time[1], 0.0, tolerance = 1e-10)
  expect_equal(df$amplitude[1], 0.5)
})

test_that("as.data.frame.praat_sound() can be used for plotting", {
  sound <- generate_sine_wave(440, 0.01, sampling_rate = 44100)
  df <- as.data.frame(sound)

  # Should be able to pass to basic plot (this doesn't actually plot, just checks it doesn't error)
  expect_no_error({
    # Simulate plot call (doesn't actually render in tests)
    plot_data <- df[, c("time", "amplitude")]
    expect_s3_class(plot_data, "data.frame")
  })
})

test_that("S3 methods validate input", {
  not_a_sound <- list(foo = "bar")

  # print and summary should still work but might not show expected format
  # (they handle non-sound input gracefully by falling back to default methods)

  # as.data.frame should fail for invalid sound
  expect_error(as.data.frame.praat_sound(not_a_sound), "praat_sound")
})

test_that("str() works with praat_sound objects", {
  sound <- create_sound(c(0.1, 0.2, 0.3), sampling_rate = 1000)

  # str() should work without error
  output <- capture.output(str(sound))

  expect_gt(length(output), 0)
  output_text <- paste(output, collapse = " ")

  # Should show it's a list with praat_sound class
  expect_match(output_text, "List|list")
  expect_match(output_text, "praat_sound")
})

test_that("S3 methods work with generated sounds", {
  sine <- generate_sine_wave(440, 0.1)
  noise <- generate_noise(0.1, seed = 42)

  # All methods should work without error
  expect_no_error(print(sine))
  expect_no_error(print(noise))
  expect_no_error(summary(sine))
  expect_no_error(summary(noise))
  expect_no_error(as.data.frame(sine))
  expect_no_error(as.data.frame(noise))
})

# ============================================================================
# Pitch object S3 methods
# ============================================================================

test_that("print.praat_pitch() produces informative console output", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # Capture print output
  output <- capture.output(print(pitch))

  # Should return multiple lines
  expect_gt(length(output), 0)

  output_text <- paste(output, collapse = " ")

  # Should mention key information
  expect_match(output_text, "praat_pitch|Pitch", ignore.case = TRUE)
  expect_match(output_text, "frames?|Frames?", ignore.case = TRUE)
  expect_match(output_text, "Hz|frequency", ignore.case = TRUE)
})

test_that("print.praat_pitch() displays correct pitch statistics", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  output <- capture.output(print(pitch))
  output_text <- paste(output, collapse = " ")

  # Should show voiced/unvoiced counts
  expect_match(output_text, "voiced|Voiced", ignore.case = TRUE)

  # Should show pitch range
  expect_match(output_text, "mean|Mean", ignore.case = TRUE)
})

test_that("summary.praat_pitch() provides statistical summary", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  output <- capture.output(summary(pitch))

  expect_gt(length(output), 0)

  output_text <- paste(output, collapse = " ")

  # Should include statistical information
  expect_match(output_text, "mean|Mean", ignore.case = TRUE)
  expect_match(output_text, "min|Min", ignore.case = TRUE)
  expect_match(output_text, "max|Max", ignore.case = TRUE)
  expect_match(output_text, "median|Median", ignore.case = TRUE)
})

test_that("summary.praat_pitch() returns invisibly", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  result <- withVisible(summary(pitch))
  expect_false(result$visible)
  expect_s3_class(result$value, "Pitch")
})

test_that("S3 methods work with pitch objects", {
  sound <- read_sound(test_path("fixtures/speech_sample.wav"))
  pitch <- extract_pitch(sound)

  # All methods should work without error
  expect_no_error(print(pitch))
  expect_no_error(summary(pitch))
  expect_no_error(str(pitch))
})
