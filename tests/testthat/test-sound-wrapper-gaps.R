# tests/testthat/test-sound-wrapper-gaps.R
# Coverage gap-fill for R/sound-wrapper.R (26 remaining uncovered lines):
# file loading errors, from_values validation, create_tone channels,
# create_tone_complex auto-ceiling, static-method errors, print, and the
# kaiser window shapes.

snd_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 16000)
}

test_that("Sound file loading and errors", {
  s <- Sound(system.file("extdata", "test.wav", package = "pladdrr"))
  expect_s3_class(s, "Sound")
  expect_gt(s$get_duration(), 0)
  expect_error(Sound("nonexistent_file.wav"), "not found")
})

test_that("sound_from_values validates input", {
  s <- sound_from_values(seq_len(100) / 100, sampling_rate = 16000)
  expect_s3_class(s, "Sound")
  expect_error(sound_from_values(data.frame(x = 1:10), 16000),
    "numeric vector or matrix")
})

test_that("sound_create_tone with explicit channels", {
  s <- sound_create_pure_tone(frequency = 220, duration = 0.2,
    sampling_rate = 16000, channels = 2)
  expect_s3_class(s, "Sound")
  expect_identical(s$get_number_of_channels(), 2L)
})

test_that("sound_create_tone_complex auto-ceiling", {
  s <- sound_create_tone_complex(frequency_step = 200, duration = 0.2,
                                 sampling_rate = 16000, ceiling = 0)
  expect_s3_class(s, "Sound")
  expect_gt(s$get_duration(), 0)
})

test_that("Sound static method error and print", {
  expect_error(Sound$no_such_static_method, "no static method")
  s <- snd_fixture()
  expect_output(print(s), "Sound")
})

test_that("to_spectrogram kaiser window shapes", {
  s <- snd_fixture()
  sg1 <- s$to_spectrogram(window_shape = "kaiser1")
  expect_s3_class(sg1, "Spectrogram")
  sg2 <- s$to_spectrogram(window_shape = "kaiser2")
  expect_s3_class(sg2, "Spectrogram")
})
