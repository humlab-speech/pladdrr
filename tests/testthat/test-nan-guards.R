# test-nan-guards.R
# Tests for NaN/NA input guards and new API methods

test_that("Ltas NaN guards return NA instead of crashing", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  ltas <- sound$to_ltas(bandwidth = 100)

  # Scalar queries

  expect_true(is.na(ltas$get_value_at_frequency(NaN)))
  expect_true(is.na(ltas$get_value_at_frequency(NA_real_)))

  # Range queries
  expect_true(is.na(ltas$get_minimum(NaN, 1000)))
  expect_true(is.na(ltas$get_maximum(100, NaN)))
  expect_true(is.na(ltas$get_mean(NaN, NaN)))

  # Batch with NaN element
  vals <- ltas$get_values_at_frequencies(c(100, NaN, 440))
  expect_length(vals, 3)
  expect_true(is.na(vals[2]))
  expect_false(is.na(vals[1]))
})

test_that("Intensity NaN guards return NA instead of crashing", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  intensity <- sound$to_intensity(minimum_pitch = 100)

  expect_true(is.na(intensity$get_value_at_time(NaN)))
  expect_true(is.na(intensity$get_mean(NaN, 0.5)))
  expect_true(is.na(intensity$get_minimum(0, NaN)))
  expect_true(is.na(intensity$get_maximum(NaN, NaN)))
  expect_true(is.na(intensity$get_standard_deviation(NaN, 0.5)))
})

test_that("Formant NaN guards return NA instead of crashing", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  formant <- sound$to_formant_burg()

  expect_true(is.na(formant$get_value_at_time(1, NaN)))

  # Batch with NaN
  vals <- formant$get_values_at_times(1, c(0.1, NaN, 0.3))
  expect_length(vals, 3)
  expect_true(is.na(vals[2]))
})

test_that("Pitch NaN guard returns NA", {

  sound <- Sound$create_tone(frequency = 200, duration = 0.5,
    sampling_rate = 16000)
  pitch <- sound$to_pitch()

  expect_true(is.na(pitch$get_value_at_time(NaN)))
})

test_that("Harmonicity NaN guards return NA", {

  sound <- Sound$create_tone(frequency = 200, duration = 0.5,
    sampling_rate = 16000)
  hnr <- sound$to_harmonicity_cc()

  expect_true(is.na(hnr$get_value_at_time(NaN)))
  expect_true(is.na(hnr$get_mean(NaN, 0.5)))

  # Batch with NaN
  vals <- hnr$get_values_at_times(c(0.1, NaN, 0.3))
  expect_length(vals, 3)
  expect_true(is.na(vals[2]))
})

# ========================================================================
# Step 2: Intensity$get_values_at_times()
# ========================================================================

test_that("Intensity$get_values_at_times works correctly", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  intensity <- sound$to_intensity(minimum_pitch = 100)

  times <- c(0.1, 0.2, 0.3)
  vals <- intensity$get_values_at_times(times)

  expect_length(vals, 3)
  expect_true(is.numeric(vals))

  # Should match individual calls
  for (i in seq_along(times)) {
    expect_equal(vals[i], intensity$get_value_at_time(times[i]),
      tolerance = 1e-10)
  }

  # NaN handling
  vals_nan <- intensity$get_values_at_times(c(0.1, NaN, 0.3))
  expect_true(is.na(vals_nan[2]))
  expect_false(is.na(vals_nan[1]))
})

# ========================================================================
# Step 3: Formant$get_values_at_times interpolation param
# ========================================================================

test_that("Formant$get_values_at_times accepts interpolation param", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  formant <- sound$to_formant_burg()

  times <- c(0.1, 0.2, 0.3)

  # Should work with both interpolation values (API compat only)
  vals_linear <- formant$get_values_at_times(1, times, interpolation = "linear")
  vals_nearest <- formant$get_values_at_times(1, times,
    interpolation = "nearest")

  expect_length(vals_linear, 3)
  expect_length(vals_nearest, 3)
})

# ========================================================================
# Step 4: Spectrogram$as_matrix dimnames
# ========================================================================

test_that("Spectrogram$as_matrix includes dimnames by default", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  spec <- sound$to_spectrogram()

  mat <- spec$as_matrix()
  expect_false(is.null(rownames(mat)))
  expect_false(is.null(colnames(mat)))

  # Dimensions should match
  expect_length(rownames(mat), nrow(mat))
  expect_length(colnames(mat), ncol(mat))

  # Dimnames should be numeric frequency and time values (no NAs from
  #  conversion)
  expect_false(anyNA(as.numeric(rownames(mat))))
  expect_false(anyNA(as.numeric(colnames(mat))))
})

test_that("Spectrogram$as_matrix(include_dimnames=FALSE) omits names", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5,
    sampling_rate = 16000)
  spec <- sound$to_spectrogram()

  mat <- spec$as_matrix(include_dimnames = FALSE)
  expect_null(rownames(mat))
  expect_null(colnames(mat))
})
