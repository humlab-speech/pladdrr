# test-durationtier-r6.R - Tests for R/durationtier-wrapper.R (DurationTier object)

test_that("DurationTier constructs and reports start/end/points", {
  dt <- DurationTier(0, 1)
  expect_s3_class(dt, "DurationTier")
  expect_s3_class(dt, "PraatObject")
  expect_true(dt$is_valid())
  expect_equal(dt$get_start_time(), 0)
  expect_equal(dt$get_end_time(), 1)
  expect_equal(dt$get_number_of_points(), 0)
})

test_that("DurationTier add_point/remove_point/value queries work", {
  dt <- DurationTier(0, 1)

  # add_point() returns self invisibly, allowing chaining
  ret <- dt$add_point(0.25, 1.0)
  expect_identical(ret, dt)
  dt$add_point(0.75, 1.5)

  expect_equal(dt$get_number_of_points(), 2)
  expect_equal(dt$get_time_from_index(1), 0.25)
  expect_equal(dt$get_value_at_index(1), 1.0)
  expect_equal(dt$get_time_from_index(2), 0.75)
  expect_equal(dt$get_value_at_index(2), 1.5)

  # get_value_at_time() linearly interpolates between points, holds the edge
  # value outside the point range
  expect_equal(dt$get_value_at_time(0.5), 1.25)
  expect_equal(dt$get_value_at_time(0), 1.0)
  expect_equal(dt$get_value_at_time(1), 1.5)

  # get_mean() with default tmin/tmax = NULL uses the full tier domain
  # (get_xmin()/get_xmax()), not just the point range; for this linear tier
  # the curve mean equals the midpoint value
  expect_equal(dt$get_mean(), 1.25)
  expect_equal(dt$get_mean(0, 1), dt$get_mean())
  expect_equal(dt$get_mean(0.25, 0.75), 1.25)

  # remove_point() returns self invisibly
  ret2 <- dt$remove_point(1)
  expect_identical(ret2, dt)
  expect_equal(dt$get_number_of_points(), 1)
  expect_equal(dt$get_time_from_index(1), 0.75)

  # out-of-range point indices error
  expect_error(dt$get_time_from_index(5), "out of range")
  expect_error(dt$get_value_at_index(0), "out of range")
  expect_error(dt$remove_point(99), "out of range")
})

test_that("DurationTier as_data_frame, save, print", {
  dt <- DurationTier(0, 1)
  dt$add_point(0.25, 1.0)
  dt$add_point(0.75, 1.5)

  df <- dt$as_data_frame()
  expect_s3_class(df, "data.frame")
  expect_named(df, c("time", "duration_factor"))
  expect_equal(df$time, c(0.25, 0.75))
  expect_equal(df$duration_factor, c(1.0, 1.5))

  # as.data.frame.DurationTier() S3 method delegates to as_data_frame()
  expect_equal(as.data.frame(dt), df)

  # empty tier -> zero-row data frame with the right columns/types
  empty_df <- DurationTier(0, 1)$as_data_frame()
  expect_equal(nrow(empty_df), 0)
  expect_named(empty_df, c("time", "duration_factor"))

  # get_xptr() returns the raw external pointer
  expect_type(dt$get_xptr(), "externalptr")

  # save() round-trips to a Praat text file and returns self invisibly
  tmp <- tempfile(fileext = ".DurationTier")
  on.exit(unlink(tmp), add = TRUE)
  ret <- dt$save(tmp)
  expect_identical(ret, dt)
  expect_true(file.exists(tmp))
  saved <- readLines(tmp)
  expect_true(any(grepl('Object class = "DurationTier"', saved, fixed = TRUE)))

  # print() output, both direct and via the S3 print.DurationTier() method
  expect_output(dt$print(), "<Praat DurationTier>")
  expect_output(print(dt), "Time domain: 0.000 to 1.000 s")
  expect_output(print(dt), "Number of points: 2")
})

test_that("DurationTier() reconstructs from an external pointer", {
  dt <- DurationTier(0, 1)
  dt$add_point(0.75, 1.5)

  xptr <- dt$get_xptr()
  dt2 <- DurationTier(.xptr = xptr)
  expect_s3_class(dt2, "DurationTier")
  expect_equal(dt2$get_number_of_points(), 1)
  expect_equal(dt2$get_time_from_index(1), 0.75)
  expect_equal(dt2$get_value_at_index(1), 1.5)
})

test_that("DurationTier() requires either (tmin, tmax) or .xptr", {
  expect_error(DurationTier(), "Must provide either")
  expect_error(DurationTier(tmin = 0), "Must provide either")
  expect_error(DurationTier(tmax = 1), "Must provide either")
})
