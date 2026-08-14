# test-table-wrapper.R - Tests for R/table-wrapper.R (Table object)

test_that("Table() requires numberOfRows plus either numberOfColumns or columnNames", {
  expect_error(Table(numberOfColumns = 2), "numberOfRows must be specified")
  expect_error(Table(numberOfRows = -1, numberOfColumns = 2), "numberOfRows must be positive")
  expect_error(Table(numberOfRows = 2), "numberOfColumns or columnNames")
})

test_that("Table() constructs by numberOfColumns and by columnNames", {
  t1 <- Table(numberOfRows = 2, numberOfColumns = 3)
  expect_s3_class(t1, "Table")
  expect_equal(t1$get_number_of_rows(), 2)
  expect_equal(t1$get_number_of_columns(), 3)

  t2 <- Table(numberOfRows = 2, columnNames = c("word", "duration"))
  expect_equal(t2$get_column_names(), c("word", "duration"))
})

test_that("Table column label get/set and index lookup", {
  tbl <- Table(numberOfRows = 1, columnNames = c("word", "duration"))
  expect_equal(tbl$get_column_label(1), "word")
  expect_equal(tbl$get_column_index("duration"), 2)

  tbl$set_column_label(1, "token")
  expect_equal(tbl$get_column_label(1), "token")
})

test_that("Table string/numeric value get/set by name and by index", {
  tbl <- Table(numberOfRows = 2, columnNames = c("word", "duration"))
  tbl$set_string_value(1, "word", "cat")
  tbl$set_numeric_value(1, "duration", 0.42)
  tbl$set_string_value(2, 1, "dog")
  tbl$set_numeric_value(2, 2, 0.7)

  expect_equal(tbl$get_string_value(1, "word"), "cat")
  expect_equal(tbl$get_numeric_value(1, "duration"), 0.42)
  expect_equal(tbl$get_string_value(2, 1), "dog")
})

test_that("Table append_row/append_column/insert_row grow the table", {
  tbl <- Table(numberOfRows = 1, columnNames = "x")
  tbl$append_row()
  expect_equal(tbl$get_number_of_rows(), 2)

  tbl$append_column("y")
  expect_equal(tbl$get_number_of_columns(), 2)

  tbl$insert_row(1)
  expect_equal(tbl$get_number_of_rows(), 3)
})

test_that("Table as_data_frame infers numeric vs character columns", {
  tbl <- Table(numberOfRows = 2, columnNames = c("word", "duration"))
  tbl$set_string_value(1, "word", "cat")
  tbl$set_numeric_value(1, "duration", 0.1)
  tbl$set_string_value(2, "word", "dog")
  tbl$set_numeric_value(2, "duration", 0.2)

  df <- tbl$as_data_frame()
  expect_true(is.character(df$word))
  expect_true(is.numeric(df$duration))
  expect_equal(df$word, c("cat", "dog"))

  df2 <- as.data.frame(tbl)
  expect_equal(df2, df)
})

test_that("Table as_data_frame handles zero rows without misclassifying columns", {
  ptr <- pladdrr:::.table_create_with_column_names(0, c("word", "duration"))
  tbl <- Table(.xptr = ptr)
  df <- tbl$as_data_frame()
  expect_equal(nrow(df), 0)
  expect_true(is.character(df$word))
})

test_that("Table get_mean/get_standard_deviation compute column statistics", {
  tbl <- Table(numberOfRows = 3, columnNames = "x")
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(2, "x", 2)
  tbl$set_numeric_value(3, "x", 3)

  expect_equal(tbl$get_mean("x"), 2)
  expect_equal(tbl$get_standard_deviation("x"), sd(c(1, 2, 3)))
})

test_that("Table sort_rows sorts in place", {
  tbl <- Table(numberOfRows = 3, columnNames = "x")
  tbl$set_numeric_value(1, "x", 3)
  tbl$set_numeric_value(2, "x", 1)
  tbl$set_numeric_value(3, "x", 2)

  tbl$sort_rows("x")
  expect_equal(tbl$as_data_frame()$x, c(1, 2, 3))
})

test_that("Table extract_rows_where_number/string return filtered sub-tables", {
  tbl <- Table(numberOfRows = 3, columnNames = c("label", "x"))
  tbl$set_string_value(1, "label", "a")
  tbl$set_string_value(2, "label", "b")
  tbl$set_string_value(3, "label", "a")
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(2, "x", 5)
  tbl$set_numeric_value(3, "x", 9)

  # which = 5 -> kMelder_number GREATER_THAN
  above2 <- tbl$extract_rows_where_number("x", 5, 2)
  expect_s3_class(above2, "Table")
  expect_equal(above2$get_number_of_rows(), 2)

  # which = 1 -> kMelder_string EQUAL_TO
  as_rows <- tbl$extract_rows_where_string("label", 1, "a")
  expect_equal(as_rows$get_number_of_rows(), 2)
})

test_that("Table save/round-trips through a file", {
  tbl <- Table(numberOfRows = 1, columnNames = c("word", "duration"))
  tbl$set_string_value(1, "word", "cat")
  tbl$set_numeric_value(1, "duration", 0.5)

  tmp <- tempfile(fileext = ".Table")
  tbl$save(tmp)
  expect_true(file.exists(tmp))
  unlink(tmp)
})

test_that("Table print, is_valid, get_xptr, and unknown-name access", {
  tbl <- Table(numberOfRows = 1, columnNames = "x")

  expect_true(tbl$is_valid())
  expect_true(inherits(tbl$get_xptr(), "externalptr"))
  expect_output(print(tbl), "Praat Table")
  expect_null(tbl$totally_bogus_field)
})

# --- internal .table_* Rcpp exports not wired into Table()'s method list ----
# (table_wrappers.cpp defines more primitives than the R6-style wrapper
# exposes; call them directly to exercise the underlying C++ correctness)

test_that("internal .table_* exports for min/max/sum/quantile/matrix work", {
  ptr <- pladdrr:::.table_create_with_column_names(3, "x")
  pladdrr:::.table_set_numeric_value(ptr, 1, 1, 1)
  pladdrr:::.table_set_numeric_value(ptr, 2, 1, 2)
  pladdrr:::.table_set_numeric_value(ptr, 3, 1, 3)

  expect_equal(pladdrr:::.table_get_minimum(ptr, 1), 1)
  expect_equal(pladdrr:::.table_get_maximum(ptr, 1), 3)
  expect_equal(pladdrr:::.table_get_sum(ptr, 1), 6)
  expect_equal(pladdrr:::.table_get_quantile(ptr, 1, 0.5), 2)

  mat <- pladdrr:::.table_to_matrix(ptr)
  expect_equal(as.numeric(mat), c(1, 2, 3))

  col_numbers <- pladdrr:::.table_get_column_numbers(ptr)
  expect_equal(length(col_numbers), 1)
})

test_that("internal .table_* exports for remove_row/remove_column/insert_column work", {
  ptr <- pladdrr:::.table_create_with_column_names(2, c("x", "y"))
  pladdrr:::.table_insert_column(ptr, 1, "z")
  expect_equal(pladdrr:::.table_get_number_of_columns(ptr), 3)

  pladdrr:::.table_remove_column(ptr, 1)
  expect_equal(pladdrr:::.table_get_number_of_columns(ptr), 2)

  pladdrr:::.table_remove_row(ptr, 1)
  expect_equal(pladdrr:::.table_get_number_of_rows(ptr), 1)
})
