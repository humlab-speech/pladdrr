# test-harmonicity-r6.R - Tests for R/harmonicity.R (the live R6 Harmonicity
# class, not a deprecated S3 wrapper -- had no dedicated test file before).

hnr_of_tone <- function(freq = 150, dur = 1.0, sr = 44100) {
  Sound$create_tone(frequency = freq, duration = dur, sampling_rate = sr)$to_harmonicity_cc(time_step = 0.01, min_pitch = 75)
}

test_that("Harmonicity() requires a pointer", {
  expect_error(Harmonicity(), "should be created from Sound objects")
})

test_that("Harmonicity is constructed via Sound$to_harmonicity_cc()/to_harmonicity_ac()", {
  hnr <- hnr_of_tone()
  expect_s3_class(hnr, "Harmonicity")
  expect_true(hnr$is_valid())

  hnr_ac <- Sound$create_tone(frequency = 150, duration = 1.0, sampling_rate = 44100)$to_harmonicity_ac(time_step = 0.01, min_pitch = 75)
  expect_s3_class(hnr_ac, "Harmonicity")
})

test_that("Harmonicity time-domain accessors are consistent", {
  hnr <- hnr_of_tone()

  expect_equal(hnr$get_start_time(), 0)
  expect_gt(hnr$get_end_time(), 0)
  expect_gt(hnr$get_number_of_frames(), 0)
  expect_equal(hnr$get_sampling_period(), 0.01, tolerance = 1e-6)

  t1 <- hnr$get_time_from_frame(1)
  expect_equal(hnr$get_frame_from_time(t1), 1)
})

test_that("Harmonicity point queries return numeric HNR values", {
  hnr <- hnr_of_tone()

  val <- hnr$get_value_at_time(0.5, interpolation = "cubic")
  expect_true(is.numeric(val))

  vals <- hnr$get_values_at_times(c(0.2, 0.5, 0.8))
  expect_length(vals, 3)

  raw_vals <- hnr$get_values_vector()
  raw_times <- hnr$get_times_vector()
  expect_length(raw_vals, length(raw_times))
  expect_length(raw_vals, hnr$get_number_of_frames())
})

test_that("Harmonicity statistics over a time range", {
  hnr <- hnr_of_tone()

  mean_hnr <- hnr$get_mean()
  expect_true(is.numeric(mean_hnr))

  min_hnr <- hnr$get_minimum(interpolation = "parabolic")
  max_hnr <- hnr$get_maximum(interpolation = "parabolic")
  expect_lte(min_hnr, max_hnr)

  sd_hnr <- hnr$get_standard_deviation()
  expect_true(is.numeric(sd_hnr))

  t_min <- hnr$get_time_of_minimum()
  t_max <- hnr$get_time_of_maximum()
  expect_gte(t_min, hnr$get_start_time()); expect_lte(t_min, hnr$get_end_time())
  expect_gte(t_max, hnr$get_start_time()); expect_lte(t_max, hnr$get_end_time())
})

test_that("Harmonicity get_statistics_batch computes per-interval stats in one call", {
  hnr <- hnr_of_tone()

  stats <- hnr$get_statistics_batch(from_times = c(0, 0.5), to_times = c(0.5, 1.0),
                                     metrics = c("mean", "min", "max", "stdev"))
  expect_equal(nrow(stats), 2)
  expect_true(all(c("mean", "min", "max", "stdev") %in% colnames(stats)))
})

test_that("Harmonicity as_data_frame/as_matrix export the frame-level data", {
  hnr <- hnr_of_tone()

  df <- hnr$as_data_frame()
  expect_named(df, c("time", "hnr_db", "voiced"))
  expect_equal(nrow(df), hnr$get_number_of_frames())

  mat <- hnr$as_matrix()
  expect_equal(rownames(mat), c("time", "hnr_db"))
})

test_that("Harmonicity print and unknown $ access", {
  hnr <- hnr_of_tone()

  expect_output(print(hnr), "Praat Harmonicity")
  expect_null(hnr$totally_bogus_field)

  df <- as.data.frame(hnr)
  expect_equal(df, hnr$as_data_frame())
})
