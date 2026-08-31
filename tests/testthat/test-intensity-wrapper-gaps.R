# tests/testthat/test-intensity-wrapper-gaps.R
# Coverage gap-fill for R/intensity-wrapper.R (was ~62%): the value queries,
# frame/geometry getters, and conversions.

intensity_fixture <- function() {
  Sound$create_tone(frequency = 220, duration = 0.3,
    sampling_rate = 16000)$to_intensity()
}

test_that("Intensity value queries return numerics", {
  it <- intensity_fixture()
  v <- it$get_value_at_time(it$get_start_time() + 0.05)
  expect_type(v, "double")
  m <- it$get_mean()
  expect_type(m, "double")
  mn <- it$get_minimum()
  expect_type(mn, "double")
  mx <- it$get_maximum()
  expect_type(mx, "double")
  sd <- it$get_standard_deviation()
  expect_gte(sd, 0)
  q <- it$get_quantile(quantile = 0.5)
  expect_type(q, "double")
  tmin <- it$get_time_of_minimum()
  expect_type(tmin, "double")
  tmax <- it$get_time_of_maximum()
  expect_type(tmax, "double")
})

test_that("Intensity frame/geometry getters", {
  it <- intensity_fixture()
  expect_gte(it$get_number_of_frames(), 1L)
  expect_gt(it$get_sampling_period(), 0)
  expect_gte(it$get_start_time(), 0)
  expect_gt(it$get_end_time(), it$get_start_time())
  expect_equal(it$get_xmin(), it$get_start_time(),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(it$get_xmax(), it$get_end_time(),
    tolerance = sqrt(.Machine$double.eps))
  n <- it$get_number_of_frames()
  t1 <- it$get_time_from_frame(1)
  f1 <- it$get_frame_from_time(t1)
  expect_gte(f1, 1)
  expect_lte(f1, n)
})

test_that("Intensity vector/statistics conversions", {
  it <- intensity_fixture()
  tv <- it$get_times_vector()
  expect_type(tv, "double")
  vv <- it$get_values_vector()
  expect_type(vv, "double")
  expect_length(vv, length(tv))
  vals <- it$get_values_at_times(tv[seq_len(min(3, length(tv)))])
  expect_type(vals, "double")
  stats <- it$get_statistics()
  expect_type(stats, "list")
  expect_true(all(c("mean", "stdev", "min", "max") %in% names(stats)))
})

test_that("Intensity down_to_intensity_tier and as_data_frame", {
  it <- intensity_fixture()
  tier <- it$down_to_intensity_tier()
  expect_s3_class(tier, "IntensityTier")
  df <- it$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
})
