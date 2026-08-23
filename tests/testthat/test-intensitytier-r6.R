# test-intensitytier-r6.R
# Coverage gap-fill for src/modules/intensitytier_module.cpp (Task 30)
#
# IntensityTier is an R6-style S3 class wrapping the intensitytier_module
# Rcpp module. It previously had no dedicated test file.

test_that("IntensityTier constructs from a time range and reports basics", {
  tier <- IntensityTier(tmin = 0.0, tmax = 1.0)

  expect_s3_class(tier, "IntensityTier")
  expect_true(tier$is_valid())
  expect_equal(tier$get_start_time(), 0.0, tolerance = 1e-9)
  expect_equal(tier$get_end_time(), 1.0, tolerance = 1e-9)
  expect_equal(tier$get_number_of_points(), 0)
})

test_that("IntensityTier requires tmin/tmax or xptr", {
  expect_error(IntensityTier(), "tmin, tmax")
})

test_that("IntensityTier can add, query, and remove points", {
  tier <- IntensityTier(tmin = 0.0, tmax = 1.0)
  expect_invisible(tier$add_point(0.5, 70.0))

  expect_equal(tier$get_number_of_points(), 1)
  expect_equal(tier$get_time_from_index(1), 0.5, tolerance = 1e-9)
  expect_equal(tier$get_value_at_index(1), 70.0, tolerance = 1e-9)
  expect_type(tier$get_value_at_time(0.5), "double")

  expect_invisible(tier$remove_point(1))
  expect_equal(tier$get_number_of_points(), 0)
})

test_that("IntensityTier get_mean, as_data_frame, save, print work", {
  tier <- IntensityTier(tmin = 0.0, tmax = 1.0)
  tier$add_point(0.2, 60.0)
  tier$add_point(0.8, 80.0)

  expect_type(tier$get_mean(0.0, 1.0), "double")

  df <- tier$as_data_frame()
  expect_s3_class(df, "data.frame")

  tmp <- tempfile(fileext = ".IntensityTier")
  on.exit(unlink(tmp), add = TRUE)
  tier$save(tmp)
  expect_true(file.exists(tmp))

  expect_output(print(tier), "IntensityTier")
})
