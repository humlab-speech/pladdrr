# tests/testthat/test-spectrumtier-wrapper-gaps.R
# Coverage gap-fill for R/spectrumtier-wrapper.R (was ~65%): geometry,
# indexed access, and exports.

st_fixture <- function() {
  l <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)$to_ltas()
  l$to_spectrum_tier_peaks()
}

test_that("SpectrumTier geometry and indexed access", {
  st <- st_fixture()
  expect_true(st$is_valid())
  expect_lte(st$get_lowest_frequency(), st$get_highest_frequency())
  expect_gte(st$get_number_of_points(), 1L)
  f <- st$get_frequency_from_index(1)
  expect_type(f, "double")
  v <- st$get_value_at_index(1)
  expect_type(v, "double")
})

test_that("SpectrumTier exports", {
  st <- st_fixture()
  df <- st$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("frequency" %in% names(df))
  m <- st$as_matrix()
  expect_type(m, "double")
  expect_true(is.matrix(m))
  tmp <- tempfile(fileext = ".tier")
  expect_invisible(st$save(tmp))
  expect_true(file.exists(tmp))
  expect_output(st$print(), "SpectrumTier")
})
