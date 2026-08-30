# Helper functions for testing data.table functionality

#' Test if object is a valid data.table with expected structure
#' 
#' @param object Object to test
#' @param expected_cols Character vector of expected column names
#' @param expected_rows Optional, expected number of rows
#' @param key Optional, expected key columns
expect_datatable <- function(object, expected_cols, expected_rows = NULL, key = NULL) {
  # Check it's a data.table
  testthat::expect_true(
    data.table::is.data.table(object),
    info = "Object should be a data.table"
  )
  
  # Check it also inherits from data.frame (for compatibility)
  testthat::expect_true(
    inherits(object, "data.frame"),
    info = "data.table should also inherit from data.frame"
  )
  
  # Check column names
  testthat::expect_named(
    object, 
    expected_cols,
    info = sprintf("Expected columns: %s", toString(expected_cols))
  )
  
  # Check row count if specified
  if (!is.null(expected_rows)) {
    testthat::expect_equal(
      nrow(object), 
      expected_rows,
      info = sprintf("Expected %d rows", expected_rows)
    )
  }
  
  # Check key if specified
  if (!is.null(key)) {
    actual_key <- data.table::key(object)
    testthat::expect_equal(
      actual_key,
      key,
      info = sprintf("Expected key: %s", toString(key))
    )
  }
  
  invisible(TRUE)
}

#' Test that function works with both data.frame and data.table input
#' 
#' Helper to ensure backward compatibility
#' 
#' @param func Function to test
#' @param test_data data.frame to use for testing
#' @param ... Additional arguments to func
with_both_types <- function(func, test_data, ...) {
  # Test with data.frame
  df_result <- func(test_data, ...)
  
  # Test with data.table
  dt_input <- data.table::as.data.table(test_data)
  dt_result <- func(dt_input, ...)
  
  # Results should be identical (allowing for class differences)
  testthat::expect_equal(
    as.data.frame(df_result, stringsAsFactors = FALSE),
    as.data.frame(dt_result, stringsAsFactors = FALSE),
    info = "Function should work identically with data.frame and data.table input"
  )
  
  invisible(list(df = df_result, dt = dt_result))
}

#' Expect that data.table has expected class structure
expect_dt_class <- function(object) {
  classes <- class(object)
  testthat::expect_true(
    "data.table" %in% classes,
    info = "Object should have 'data.table' class"
  )
  testthat::expect_true(
    "data.frame" %in% classes,
    info = "Object should inherit from 'data.frame'"
  )
  testthat::expect_equal(
    classes[1],
    "data.table",
    info = "First class should be 'data.table'"
  )
}

#' Test data.table performance improvement
#' 
#' Helper to verify performance gains from data.table migration
#' 
#' @param old_func Old function (returns data.frame with rbind loops)
#' @param new_func New function (returns data.table with rbindlist)
#' @param ... Arguments to both functions
#' @param min_speedup Minimum expected speedup factor (default 2x)
expect_dt_faster <- function(old_func, new_func, ..., min_speedup = 2) {
  skip_on_cran()
  
  # Run old function
  old_time <- system.time({
    old_result <- old_func(...)
  })["elapsed"]
  
  # Run new function
  new_time <- system.time({
    new_result <- new_func(...)
  })["elapsed"]
  
  # Check speedup
  speedup <- old_time / new_time
  testthat::expect_true(
    speedup >= min_speedup,
    info = sprintf(
      "Expected at least %dx speedup, got %.2fx (old: %.3fs, new: %.3fs)",
      min_speedup, speedup, old_time, new_time
    )
  )
  
  # Check results are equivalent
  testthat::expect_equal(
    as.data.frame(old_result, stringsAsFactors = FALSE),
    as.data.frame(new_result, stringsAsFactors = FALSE),
    info = "Results should be equivalent"
  )
  
  invisible(list(speedup = speedup, old_time = old_time, new_time = new_time))
}
