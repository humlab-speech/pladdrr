# test-sound-operations.R - Tests for R/sound-operations.R
# (standalone functional Sound operations: append, extract, lengthen, deepen,
# convolve, cross-correlate, auto-correlate, band-pass/stop filtering)

tone <- function(freq = 220, dur = 0.2, sr = 16000) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)
}

test_that("sounds_append concatenates with silence gap", {
  s1 <- tone(220, 0.2)
  s2 <- tone(440, 0.2)
  combined <- sounds_append(s1, s2, silence_duration = 0.1)

  expect_s3_class(combined, "Sound")
  expect_equal(combined$get_duration(), 0.5, tolerance = 1e-6)
})

test_that("sounds_append defaults silence_duration to 0", {
  s1 <- tone(220, 0.2)
  s2 <- tone(440, 0.2)
  combined <- sounds_append(s1, s2)

  expect_equal(combined$get_duration(), 0.4, tolerance = 1e-6)
})

test_that("sound_extract_part extracts the requested time range", {
  s <- tone(220, 0.5)
  part <- sound_extract_part(s, 0.1, 0.3, window_shape = 1L,
                              relative_width = 1.0, preserve_times = FALSE)

  expect_s3_class(part, "Sound")
  expect_equal(part$get_duration(), 0.2, tolerance = 1e-6)
})

test_that("sound_extract_part accepts named window shapes", {
  s <- tone(220, 0.5)
  part <- sound_extract_part(s, 0.1, 0.3, window_shape = "hanning")

  expect_s3_class(part, "Sound")
  expect_equal(part$get_duration(), 0.2, tolerance = 1e-6)
})

test_that("sound_lengthen stretches duration by the given factor", {
  s <- tone(150, 0.2)
  lengthened <- sound_lengthen(s, fmin = 75, fmax = 600, factor = 1.5)

  expect_s3_class(lengthened, "Sound")
  expect_equal(lengthened$get_duration(), s$get_duration() * 1.5, tolerance = 1e-2)
})

test_that("sound_deepen_band_modulation returns a modified Sound of the same duration", {
  s <- tone(150, 0.2)
  deepened <- sound_deepen_band_modulation(s)

  expect_s3_class(deepened, "Sound")
  expect_equal(deepened$get_duration(), s$get_duration(), tolerance = 1e-6)
})

test_that("sounds_convolve returns a Sound with combined-length duration", {
  s1 <- tone(220, 0.2)
  s2 <- tone(440, 0.2)
  conv <- sounds_convolve(s1, s2)

  expect_s3_class(conv, "Sound")
  expect_true(conv$get_duration() > 0)
})

test_that("sounds_cross_correlate returns a valid Sound", {
  s1 <- tone(220, 0.2)
  s2 <- tone(440, 0.2)
  xcorr <- sounds_cross_correlate(s1, s2)

  expect_s3_class(xcorr, "Sound")
  expect_true(xcorr$get_duration() > 0)
})

test_that("sound_auto_correlate returns a valid Sound", {
  s <- tone(220, 0.2)
  ac <- sound_auto_correlate(s)

  expect_s3_class(ac, "Sound")
  expect_true(ac$get_duration() > 0)
})

test_that("sound_filter_pass_hann_band and sound_filter_stop_hann_band preserve duration", {
  s <- tone(220, 0.2, sr = 16000)

  bp <- sound_filter_pass_hann_band(s, fmin = 100, fmax = 500, smooth = 50)
  expect_s3_class(bp, "Sound")
  expect_equal(bp$get_duration(), s$get_duration(), tolerance = 1e-6)

  bs <- sound_filter_stop_hann_band(s, fmin = 100, fmax = 500, smooth = 50)
  expect_s3_class(bs, "Sound")
  expect_equal(bs$get_duration(), s$get_duration(), tolerance = 1e-6)
})
