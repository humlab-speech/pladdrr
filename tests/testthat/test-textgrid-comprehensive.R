# Comprehensive TextGrid Tests
library(pladdrr)


test_that("TextGrid loads without errors", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  expect_s3_class(tg, "TextGrid")
  expect_s3_class(tg, "R6")
})

test_that("TextGrid basic info methods work", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  expect_equal(tg$get_start_time(), 0)
  expect_equal(tg$get_end_time(), 60)
  expect_equal(tg$get_total_duration(), 60)
  expect_equal(tg$get_number_of_tiers(), 10)
})

test_that("TextGrid tier name queries work", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  names <- tg$get_tier_names()
  expect_type(names, "character")
  expect_length(names, 10)
  expect_equal(tg$get_tier_name(1), "Tier_1_1")
  expect_equal(tg$get_tier_name(5), "Tier_1_5")
})

test_that("IntervalTier queries work", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  expect_true(tg$tier_is_interval_tier(1))
  expect_equal(tg$get_number_of_intervals(1), 400)
  
  # First interval
  start <- tg$get_interval_start_time(1, 1)
  end <- tg$get_interval_end_time(1, 1)
  text <- tg$get_interval_text(1, 1)
  
  expect_type(start, "double")
  expect_type(end, "double")
  expect_type(text, "character")
  expect_gte(start, 0)
  expect_gt(end, start)
})

test_that("PointTier queries work", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  expect_true(tg$tier_is_point_tier(5))
  expect_equal(tg$get_number_of_points(5), 403)
  
  # First point
  time <- tg$get_point_time(5, 1)
  text <- tg$get_point_text(5, 1)
  
  expect_type(time, "double")
  expect_type(text, "character")
  expect_gt(time, 0)
})

test_that("Time-based queries work", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  # Query at t=30.0
  interval_idx <- tg$get_interval_at_time(1, 30.0)
  label <- tg$get_label_at_time(1, 30.0)
  
  expect_type(interval_idx, "integer")
  expect_type(label, "character")
  expect_gt(interval_idx, 0)
  expect_lte(interval_idx, 400)
})

test_that("Large files load successfully", {
  skip_on_cran()
  
  # 10-minute file
  tg10 <- TextGrid$new('../../inst/extdata/benchmarkdata10min.TextGrid')
  expect_equal(tg10$get_total_duration(), 600)
  expect_equal(tg10$get_number_of_tiers(), 10)
  
  # 30-minute file
  tg30 <- TextGrid$new('../../inst/extdata/benchmarkdata30min.TextGrid')
  expect_equal(tg30$get_total_duration(), 1800)
  expect_equal(tg30$get_number_of_tiers(), 10)
})

test_that("TextGrid handles edge cases", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  # Query at start time
  label_start <- tg$get_label_at_time(1, 0.0)
  expect_type(label_start, "character")
  
  # Query at end time
  label_end <- tg$get_label_at_time(1, 60.0)
  expect_type(label_end, "character")
})

test_that("TextGrid errors on invalid input", {
  expect_error(
    TextGrid$new('nonexistent.TextGrid'),
    "not found"
  )
})

test_that("TextGrid tier type detection works", {
  tg <- TextGrid$new('../../inst/extdata/benchmarkdata1min.TextGrid')
  
  # Tier 1-4 are interval tiers
  expect_true(tg$tier_is_interval_tier(1))
  expect_false(tg$tier_is_point_tier(1))
  
  # Tier 5 is a point tier
  expect_true(tg$tier_is_point_tier(5))
  expect_false(tg$tier_is_interval_tier(5))
})
