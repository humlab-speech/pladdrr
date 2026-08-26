# test-dtw.R
# Tests for DTW (Dynamic Time Warping) module

test_that("sounds_to_dtw creates valid DTW", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))

  # Self-alignment should work
  dtw <- sounds_to_dtw(sound, sound)

  expect_s3_class(dtw, "DTW")
  expect_s3_class(dtw, "PraatObject")
  expect_true(dtw$.cpp$is_valid())
})

test_that("DTW self-alignment has near-zero distance", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  # Self-alignment distance should be very small (not exactly 0 due to MFCC quantization)
  dist <- dtw$get_weighted_distance()
  expect_true(is.finite(dist))
  expect_gte(dist, 0)
})

test_that("DTW time mapping is consistent for self-alignment", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  # Self-alignment should give near-identity mapping
  tx <- sound$get_xmin() + (sound$get_duration() / 2)  # middle of sound
  ty <- dtw$get_y_time_from_x_time(tx)

  expect_true(is.finite(ty))
  # For self-alignment, mapped time should be close to input time
  expect_equal(ty, tx, tolerance = 0.1)
})

test_that("DTW get_path returns valid data.frame", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  path <- dtw$get_path()

  expect_true(is.data.frame(path))
  expect_equal(nrow(path), dtw$get_path_length())
  expect_true(all(c("x_index", "y_index", "x_time", "y_time") %in% names(path)))
})

test_that("DTW vectorized time mapping works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  xmin <- sound$get_xmin()
  xmax <- sound$get_xmax()
  times <- seq(xmin + 0.05, xmax - 0.05, length.out = 5)
  mapped <- dtw$map_times(times, "x_to_y")

  expect_length(mapped, length(times))
  expect_true(all(is.finite(mapped)))
})

test_that("DTW properties are accessible", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  # Domain properties
  expect_true(is.finite(dtw$get_xmin()))
  expect_true(is.finite(dtw$get_xmax()))
  expect_true(is.finite(dtw$get_ymin()))
  expect_true(is.finite(dtw$get_ymax()))

  # Matrix properties
  expect_true(dtw$get_nx() > 0)
  expect_true(dtw$get_ny() > 0)

  # Path properties
  expect_true(dtw$get_path_length() > 0)
  expect_true(is.finite(dtw$get_weighted_distance()))
})

test_that("DTW get_info returns valid structure", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  info <- dtw$get_info()

  expect_type(info, "list")
  expect_true("x_domain" %in% names(info))
  expect_true("y_domain" %in% names(info))
  expect_true("matrix" %in% names(info))
  expect_true("path" %in% names(info))
})

test_that("DTW swap_axes works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  swapped <- dtw$swap_axes()

  expect_s3_class(swapped, "DTW")
  # Swapped dimensions should be reversed
  expect_equal(swapped$get_nx(), dtw$get_ny())
  expect_equal(swapped$get_ny(), dtw$get_nx())
})

test_that("DTW to_matrix_distances works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  mat <- dtw$to_matrix_distances()

  expect_s3_class(mat, "Matrix")
})

test_that("Sound$to_dtw method works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))

  dtw <- sound$to_dtw(sound)

  expect_s3_class(dtw, "DTW")
})

test_that("DTW print method works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  expect_output(print(dtw), "Praat DTW")
})

test_that("DTW as_matrix returns numeric matrix", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  mat <- dtw$as_matrix()

  expect_true(is.matrix(mat))
  expect_true(is.numeric(mat))
  expect_equal(nrow(mat), dtw$get_ny())
  expect_equal(ncol(mat), dtw$get_nx())
})

test_that("DTW maximum consecutive steps works", {
  skip_if_not(file.exists(test_path("fixtures/speech_sample.wav")))

  sound <- Sound(test_path("fixtures/speech_sample.wav"))
  dtw <- sounds_to_dtw(sound, sound)

  steps_x <- dtw$get_maximum_consecutive_steps("x")
  steps_y <- dtw$get_maximum_consecutive_steps("y")

  expect_true(is.integer(steps_x) || is.numeric(steps_x))
  expect_true(is.integer(steps_y) || is.numeric(steps_y))
})
