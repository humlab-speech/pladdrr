# test-amplitudetier-r6.R
# Coverage gap-fill for src/modules/amplitudetier_module.cpp (Task 30 margin)
#
# AmplitudeTier is an R6-style S3 class wrapping the amplitudetier_module
# Rcpp module. Its prior coverage was thin (test-amplitudetier.R).

test_that("AmplitudeTier constructs and reports basics", {
  tier <- amplitude_tier_create(0.0, 1.0)

  expect_s3_class(tier, "AmplitudeTier")
  expect_true(tier$is_valid())
  expect_equal(tier$get_start_time(), 0.0, tolerance = 1e-9)
  expect_equal(tier$get_end_time(), 1.0, tolerance = 1e-9)
  expect_identical(tier$get_number_of_points(), 0L)
})

test_that("AmplitudeTier requires an xptr", {
  expect_error(AmplitudeTier(), "amplitude_tier_create")
})

test_that("AmplitudeTier can add, query, and remove points", {
  tier <- amplitude_tier_create(0.0, 1.0)
  expect_invisible(tier$add_point(0.5, 0.8))

  expect_identical(tier$get_number_of_points(), 1L)
  expect_equal(tier$get_time_from_index(1), 0.5, tolerance = 1e-9)
  expect_equal(tier$get_value_at_index(1), 0.8, tolerance = 1e-9)
  expect_type(tier$get_value_at_time(0.5), "double")

  expect_invisible(tier$remove_point(1))
  expect_identical(tier$get_number_of_points(), 0L)
})

test_that("AmplitudeTier to_intensity_tier, as_data_frame, save, print work", {
  tier <- amplitude_tier_create(0.0, 1.0)
  tier$add_point(0.2, 0.5)
  tier$add_point(0.8, 0.9)

  it <- tier$to_intensity_tier(threshold_db = -50)
  expect_s3_class(it, "IntensityTier")

  df <- tier$as_data_frame()
  expect_s3_class(df, "data.frame")

  tmp <- tempfile(fileext = ".AmplitudeTier")
  on.exit(unlink(tmp), add = TRUE)
  tier$save(tmp)
  expect_true(file.exists(tmp))

  expect_output(print(tier), "AmplitudeTier")
})
