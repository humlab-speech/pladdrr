# Comprehensive TextGrid Tests
library(pladdrr)

benchmark_tg <- system.file("extdata", "benchmarkdata1min.TextGrid", package = "pladdrr")

test_that("TextGrid loads without errors", {
  tg <- TextGrid$new(benchmark_tg)
  expect_s3_class(tg, "TextGrid")
})

test_that("TextGrid basic info methods work", {
  tg <- TextGrid$new(benchmark_tg)
  
  expect_equal(tg$get_start_time(), 0)
  expect_equal(tg$get_end_time(), 60)
  expect_equal(tg$get_total_duration(), 60)
  expect_equal(tg$get_number_of_tiers(), 10)
})

test_that("TextGrid tier name queries work", {
  tg <- TextGrid$new(benchmark_tg)
  
  names <- tg$get_tier_names()
  expect_type(names, "character")
  expect_length(names, 10)
  expect_equal(tg$get_tier_name(1), "Tier_1_1")
  expect_equal(tg$get_tier_name(5), "Tier_1_5")
})

test_that("IntervalTier queries work", {
  tg <- TextGrid$new(benchmark_tg)
  
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
  tg <- TextGrid$new(benchmark_tg)
  
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
  tg <- TextGrid$new(benchmark_tg)
  
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
  skip("Large benchmark files removed to reduce package size")
  
  # These tests used 10min and 30min TextGrid files (49MB total)
  # Keep 1min file (1.2MB) for other tests
})

test_that("TextGrid handles edge cases", {
  tg <- TextGrid$new(benchmark_tg)
  
  # Query at start time
  label_start <- tg$get_label_at_time(1, 0.0)
  expect_type(label_start, "character")
  
  # Query at end time
  label_end <- tg$get_label_at_time(1, 60.0)
  expect_type(label_end, "character")
})

test_that("TextGrid errors on invalid input", {
  expect_error(
    TextGrid$new("nonexistent.TextGrid"),
    "not found"
  )
})

test_that("TextGrid tier type detection works", {
  tg <- TextGrid$new(benchmark_tg)

  # Tier 1-4 are interval tiers
  expect_true(tg$tier_is_interval_tier(1))
  expect_false(tg$tier_is_point_tier(1))

  # Tier 5 is a point tier
  expect_true(tg$tier_is_point_tier(5))
  expect_false(tg$tier_is_interval_tier(5))
})

# ----------------------------------------------------------------------------
# Coverage gap-fill: textgrid_module.cpp error/edge paths (task 21)
# ----------------------------------------------------------------------------

test_that("TextGrid is_valid() reports pointer validity", {
  tg <- TextGrid$new(benchmark_tg)
  expect_true(tg$is_valid())
})

test_that("Tier-level accessors error on out-of-range tier number", {
  tg <- TextGrid$new(benchmark_tg)
  expect_error(tg$get_tier_name(99))
  expect_error(tg$tier_is_interval_tier(99))
  expect_error(tg$tier_is_point_tier(99))
})

test_that("get_interval_start_time/end_time error on bad interval number and wrong tier type", {
  tg <- TextGrid$new(benchmark_tg)
  # out-of-range interval number on a real interval tier
  expect_error(tg$get_interval_start_time(1, 999999))
  expect_error(tg$get_interval_end_time(1, 999999))
  # wrong tier type: tier 5 is a PointTier
  expect_error(tg$get_interval_start_time(5, 1))
  expect_error(tg$get_interval_end_time(5, 1))
})

test_that("get_interval_text/get_interval_at_time/get_label_at_time error on wrong tier type", {
  tg <- TextGrid$new(benchmark_tg)
  expect_error(tg$get_interval_text(5, 1))
  expect_error(tg$get_interval_at_time(5, 0.5))
  expect_error(tg$get_label_at_time(5, 0.5))
})

test_that("get_labels_at_times returns NA outside the time domain and errors on a point tier", {
  tg <- TextGrid$new(benchmark_tg)
  labels <- tg$get_labels_at_times(1, c(-5, 30, 1000))
  expect_true(is.na(labels[1]))
  expect_false(is.na(labels[2]))
  expect_true(is.na(labels[3]))

  expect_error(tg$get_labels_at_times(5, c(0.5)))
})

test_that("set_interval_texts_batch validates length and interval numbers", {
  tg <- TextGrid$new(benchmark_tg)
  expect_error(tg$set_interval_texts_batch(1, c(1L, 2L), c("only one")))
  expect_error(tg$set_interval_texts_batch(1, c(999999L), c("x")))
})

test_that("get_all_intervals_fast/get_all_points_fast work and error on wrong tier type", {
  tg <- TextGrid$new(benchmark_tg)

  intervals <- tg$get_all_intervals_fast(1)
  expect_true(all(c("start", "end", "label") %in% names(intervals)))
  expect_length(intervals$start, 400)
  expect_error(tg$get_all_intervals_fast(5))

  points <- tg$get_all_points_fast(5)
  expect_true(all(c("time", "mark") %in% names(points)))
  expect_length(points$time, 403)
  expect_error(tg$get_all_points_fast(1))
})

test_that("set_interval_text errors on out-of-range interval number", {
  tg <- TextGrid$create(0, 1, tier_names = "phones")
  expect_error(tg$set_interval_text(1, 99, "x"))
})

test_that("insert_boundary and remove_boundary_at_time error paths", {
  tg <- TextGrid$create(0, 1, tier_names = "phones")
  tg$insert_boundary(1, 0.5)

  # inserting the exact same boundary again must error, not crash
  expect_error(tg$insert_boundary(1, 0.5))
  # removing a boundary at a time where none exists
  expect_error(tg$remove_boundary_at_time(1, 0.9))
  # invalid tier number
  expect_error(tg$insert_boundary(99, 0.2))
})

test_that("get_number_of_points errors on an interval tier; get_point_time/text error on OOB and wrong type", {
  tg <- TextGrid$new(benchmark_tg)
  expect_error(tg$get_number_of_points(1))    # tier 1 is an interval tier
  expect_error(tg$get_point_time(5, 999999))  # out of range point number
  expect_error(tg$get_point_time(1, 1))       # wrong tier type
  expect_error(tg$get_point_text(1, 1))       # wrong tier type
})

test_that("insert_point errors on an invalid tier number", {
  tg <- TextGrid$create(0, 1, tier_names = "phones tones", point_tiers = "tones")
  expect_error(tg$insert_point(99, 0.1, "x"))
})

test_that("set_point_text and remove_point work and error appropriately", {
  tg <- TextGrid$create(0, 1, tier_names = "phones tones", point_tiers = "tones")
  tg$insert_point(2, 0.3, "a")

  tg$set_point_text(2, 1, "b")
  expect_equal(tg$get_point_text(2, 1), "b")
  expect_error(tg$set_point_text(2, 99, "x"))

  tg$remove_point(2, 1)
  expect_equal(tg$get_number_of_points(2), 0)
  expect_error(tg$remove_point(2, 1))  # nothing left to remove
})

test_that("add_interval_tier, remove_tier(invalid), extract_part, get_info work", {
  tg <- TextGrid$create(0, 2, tier_names = "phones")
  tg$add_interval_tier("new_tier")
  expect_equal(tg$get_number_of_tiers(), 2)
  expect_error(tg$remove_tier(99))

  sub <- tg$extract_part(0.5, 1.5)
  expect_s3_class(sub, "TextGrid")
  expect_equal(sub$get_total_duration(), 1, tolerance = 1e-10)

  info <- tg$get_info()
  expect_equal(info$n_tiers, 2)
})

test_that("to_table_ptr() C++ module method converts a TextGrid to a Table", {
  # NOTE: the R-level tg$to_table() wrapper (R/textgrid-wrapper.R) calls
  # .cpp$to_table_ptr() with zero arguments, but the underlying C++ method
  # requires 4 arguments (include_line_numbers, time_decimals,
  # include_tier_names, include_empty_intervals) with no Rcpp-Module-level
  # defaults; calling tg$to_table() therefore always errors with
  # "could not find valid method". This looks like a pre-existing bug in
  # to_table() unrelated to this coverage task; exercising the underlying
  # C++ method directly here (as the wrapper *should* be calling it) to
  # cover the C++ implementation without changing production code.
  tg <- TextGrid$create(0, 2, tier_names = "phones")
  tg$insert_boundary(1, 1)
  tg$set_interval_text(1, 2, "hello")

  ptr <- tg$.cpp$to_table_ptr(TRUE, 3L, TRUE, TRUE)
  expect_s3_class(ptr, "externalptr")
  tbl <- Table(.xptr = ptr)
  expect_s3_class(tbl, "Table")
})

test_that("save() errors when the destination path is not writable", {
  tg <- TextGrid$create(0, 1, tier_names = "phones")
  bad_path <- file.path(tempdir(), "no_such_dir_task21_xyz", "out.TextGrid")
  expect_error(tg$save(bad_path))
})

test_that("Module_TextGrid_create/Module_TextGrid_read factory functions work directly", {
  mod <- pladdrr:::get_module("textgrid_module")

  ptr <- mod$TextGrid_create(0, 1, "phones", "")
  expect_s3_class(ptr, "externalptr")
  tg <- TextGrid(.xptr = ptr)
  expect_equal(tg$get_number_of_tiers(), 1)

  # Praat throws when there are no tiers to create
  expect_error(mod$TextGrid_create(0, 1, "", ""))

  tmp <- tempfile(fileext = ".TextGrid")
  tg$save(tmp)
  ptr2 <- mod$TextGrid_read(tmp)
  tg2 <- TextGrid(.xptr = ptr2)
  expect_equal(tg2$get_number_of_tiers(), 1)

  # Reading a nonexistent file must error, not crash
  expect_error(mod$TextGrid_read(file.path(tempdir(), "does_not_exist_task21_xyz.TextGrid")))
})
