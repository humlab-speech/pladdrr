# test-pitchtier-wrapper.R - Tests for R/pitchtier-wrapper.R (PitchTier object)

test_that("PitchTier() requires (tmin, tmax) or .xptr", {
  expect_error(PitchTier(), "Must provide")
})

test_that("PitchTier construction and point queries", {
  tier <- PitchTier(0, 1)
  expect_s3_class(tier, "PitchTier")
  expect_equal(tier$get_number_of_points(), 0)

  tier$add_point(0.2, 100)
  tier$add_point(0.5, 150)
  tier$add_point(0.8, 200)

  expect_equal(tier$get_number_of_points(), 3)
  expect_equal(tier$get_time_from_index(2), 0.5)
  expect_equal(tier$get_value_at_index(2), 150)
  expect_equal(tier$get_minimum(), 100)
  expect_equal(tier$get_maximum(), 200)
})

test_that("PitchTier get_mean/get_standard_deviation over the full and partial domain", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.2, 100)
  tier$add_point(0.8, 200)

  full_mean <- tier$get_mean()
  expect_true(is.numeric(full_mean))

  partial_mean <- tier$get_mean(0.2, 0.8)
  expect_true(is.numeric(partial_mean))

  sd_val <- tier$get_standard_deviation()
  expect_true(is.numeric(sd_val))
})

test_that("PitchTier remove_point and remove_points_between", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.2, 100)
  tier$add_point(0.5, 150)
  tier$add_point(0.8, 200)

  tier$remove_point(2)
  expect_equal(tier$get_number_of_points(), 2)

  tier$remove_points_between(0, 1)
  expect_equal(tier$get_number_of_points(), 0)
})

test_that("PitchTier multiply_frequencies_in_range and shift_frequencies_in_range", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.5, 100)

  tier$multiply_frequencies_in_range(0, 1, 2)
  expect_equal(tier$get_value_at_index(1), 200)

  tier$shift_frequencies_in_range(0, 1, 50, unit = "hertz")
  expect_equal(tier$get_value_at_index(1), 250)
})

test_that("PitchTier stylize and interpolate_quadratically run without error", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.1, 100)
  tier$add_point(0.5, 150)
  tier$add_point(0.9, 120)

  expect_silent(tier$stylize(2, FALSE))
  expect_silent(tier$interpolate_quadratically(4, FALSE))
  expect_true(tier$get_number_of_points() >= 3)
})

test_that("PitchTier as_data_frame/as_matrix reflect the stored points", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.2, 100)
  tier$add_point(0.8, 200)

  df <- tier$as_data_frame()
  expect_named(df, c("time", "frequency"))
  expect_equal(nrow(df), 2)

  mat <- tier$as_matrix()
  expect_equal(colnames(mat), c("time", "frequency"))
  expect_equal(nrow(mat), 2)
})

test_that("PitchTier save/pitchtier_from_file round-trips through a file", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.5, 150)

  tmp <- tempfile(fileext = ".PitchTier")
  tier$save(tmp)
  loaded <- pladdrr:::pitchtier_from_file(tmp)
  unlink(tmp)

  expect_s3_class(loaded, "PitchTier")
  expect_equal(loaded$get_number_of_points(), 1)
  expect_equal(loaded$get_value_at_index(1), 150)
})

test_that("PitchTier to_sound_pulse_train/to_sound_phonation/to_sound_sine produce Sounds", {
  tier <- PitchTier(0, 0.2)
  tier$add_point(0.1, 150)

  pulse <- tier$to_sound_pulse_train(sample_rate = 16000)
  expect_s3_class(pulse, "Sound")
  expect_true(pulse$get_duration() > 0)

  phon <- tier$to_sound_phonation(sample_rate = 16000)
  expect_s3_class(phon, "Sound")

  sine <- tier$to_sound_sine(sample_rate = 16000)
  expect_s3_class(sine, "Sound")
})

test_that("PitchTier to_pitch produces a Pitch object", {
  tier <- PitchTier(0, 0.5)
  tier$add_point(0.25, 150)

  pitch <- tier$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
  expect_s3_class(pitch, "Pitch")
})

test_that("PitchTier print, is_valid, get_xptr, and unknown-name access", {
  tier <- PitchTier(0, 1)
  tier$add_point(0.5, 150)

  expect_true(tier$is_valid())
  expect_type(tier$get_xptr(), "externalptr")
  expect_output(print(tier), "Praat PitchTier")
  expect_null(tier$totally_bogus_field)
})

test_that("PitchTier$new static method loads a PitchTier from file", {
  expect_error(PitchTier$bogus_static_method, "Available: new")

  original <- PitchTier(0, 1)
  original$add_point(0.5, 150)
  tmp <- tempfile(fileext = ".PitchTier")
  original$save(tmp)

  loaded <- PitchTier$new(tmp)
  unlink(tmp)

  expect_s3_class(loaded, "PitchTier")
  expect_equal(loaded$get_number_of_points(), 1)
})
