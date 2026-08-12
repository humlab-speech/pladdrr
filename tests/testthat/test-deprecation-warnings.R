test_that("deprecated S3 extract functions emit warnings", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)

  expect_warning(extract_pitch(sound), "deprecated")
  expect_warning(extract_formants(sound), "deprecated")
  expect_warning(extract_intensity(sound), "deprecated")
})

test_that("deprecated create_sound emits warning", {

  expect_warning(create_sound(rnorm(100), 44100), "deprecated")
})
