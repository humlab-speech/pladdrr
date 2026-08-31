# test-ltas-spectrumtier.R - Tests for newly exposed Ltas query methods
# and the SpectrumTier peak-picking class.

test_that("Ltas exposes get_value_in_bin matching get_value_at_frequency", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  n_bins <- ltas$get_number_of_bins()
  expect_gt(n_bins, 0)

  bin_freq <- ltas$get_frequency_from_bin(1L)
  value_in_bin <- ltas$get_value_in_bin(1L)
  value_at_freq <- ltas$get_value_at_frequency(bin_freq, interpolate = FALSE)

  expect_type(value_in_bin, "double")
  expect_equal(value_in_bin, value_at_freq, tolerance = 1e-6)
})

test_that("Ltas get_frequency_range matches highest minus lowest frequency", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  expect_equal(
    ltas$get_frequency_range(),
    ltas$get_highest_frequency() - ltas$get_lowest_frequency()
  , tolerance = sqrt(.Machine$double.eps))
})

test_that(
  "Ltas get_standard_deviation returns a finite non-negative dB value", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  sd_db <- ltas$get_standard_deviation(0, 0, unit = "dB")
  expect_type(sd_db, "double")
  expect_true(is.finite(sd_db))
  expect_gte(sd_db, 0)
})

test_that("Ltas get_local_peak_height is positive at a strong tone peak", {
  sound <- Sound$create_tone(frequency = 1000, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 20)

  height <- ltas$get_local_peak_height(
    environment_min = 500, environment_max = 1500,
    peak_min = 950, peak_max = 1050,
    unit = "dB"
  )
  expect_type(height, "double")
  expect_true(is.finite(height))
  expect_gt(height, 0)
})

test_that("Ltas to_matrix returns a Matrix object with matching data", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  mat_obj <- ltas$to_matrix()
  expect_s3_class(mat_obj, "Matrix")

  ltas_df <- ltas$as_data_frame()
  expect_equal(mat_obj$get_number_of_columns(), nrow(ltas_df),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("Ltas save writes a readable Praat text file", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  temp_file <- tempfile(fileext = ".Ltas")
  on.exit(unlink(temp_file))

  result <- ltas$save(temp_file)
  expect_true(file.exists(temp_file))
  expect_identical(result, ltas)
})

test_that("Ltas to_spectrum_tier_peaks finds the tone's peak", {
  sound <- Sound$create_tone(frequency = 1000, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 20)

  peaks <- ltas$to_spectrum_tier_peaks()
  expect_s3_class(peaks, "SpectrumTier")
  expect_true(peaks$is_valid())

  n_points <- peaks$get_number_of_points()
  expect_gt(n_points, 0)

  freqs <- vapply(seq_len(n_points), peaks$get_frequency_from_index, numeric(1))
  expect_true(any(abs(freqs - 1000) < 50))
})

test_that(
  "SpectrumTier as_data_frame and as_matrix expose frequency and power", {
  sound <- Sound$create_tone(frequency = 1000, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 20)
  peaks <- ltas$to_spectrum_tier_peaks()

  df <- peaks$as_data_frame()
  expect_named(df, c("frequency", "power_db"))
  expect_equal(nrow(df), peaks$get_number_of_points(),
    tolerance = sqrt(.Machine$double.eps))

  mat <- peaks$as_matrix()
  expect_equal(rownames(mat), c("frequency", "power_db"),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(ncol(mat), peaks$get_number_of_points(),
    tolerance = sqrt(.Machine$double.eps))
})

test_that("SpectrumTier save writes a readable Praat text file", {
  sound <- Sound$create_tone(frequency = 1000, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 20)
  peaks <- ltas$to_spectrum_tier_peaks()

  temp_file <- tempfile(fileext = ".SpectrumTier")
  on.exit(unlink(temp_file))

  result <- peaks$save(temp_file)
  expect_true(file.exists(temp_file))
  expect_identical(result, peaks)
})
