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
  expect_type(df$word, "character")
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
  expect_type(df$word, "character")
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
  expect_type(tbl$get_xptr(), "externalptr")
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
  expect_length(col_numbers, 1)
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

test_that("internal .table_get_numeric_value returns a cell's value directly", {
  # .table_get_numeric_value is a bare Rcpp::export never called from the R6
  # dispatch table (Table's get_numeric_value method goes through the
  # RTable module instead) or from any other existing test.
  ptr <- pladdrr:::.table_create_with_column_names(1, "x")
  pladdrr:::.table_set_numeric_value(ptr, 1, 1, 42)
  expect_equal(pladdrr:::.table_get_numeric_value(ptr, 1, 1), 42)
})

test_that("internal .table_get_mean/stdev/minimum/maximum/sum/quantile error on out-of-range column", {
  # Verified interactively: an out-of-range column number reaches Praat's
  # Table_getMean() et al., which throw a MelderError that these bare
  # wrappers catch and re-raise as a plain R error (never a crash).
  tbl <- Table(numberOfRows = 2, columnNames = "x")
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(2, "x", 2)
  ptr <- tbl$get_xptr()

  expect_error(pladdrr:::.table_get_mean(ptr, 99), "Failed to get mean")
  expect_error(pladdrr:::.table_get_stdev(ptr, 99), "Failed to get standard deviation")
  expect_error(pladdrr:::.table_get_minimum(ptr, 99), "Failed to get minimum")
  expect_error(pladdrr:::.table_get_maximum(ptr, 99), "Failed to get maximum")
  expect_error(pladdrr:::.table_get_sum(ptr, 99), "Failed to get sum")
  expect_error(pladdrr:::.table_get_quantile(ptr, 99, 0.5), "Failed to get quantile")
})

test_that("internal .table_remove_row/.table_remove_column/.table_insert_column error on out-of-range index", {
  ptr <- pladdrr:::.table_create_with_column_names(1, "x")
  expect_error(pladdrr:::.table_remove_row(ptr, 99), "Failed to remove row")
  expect_error(pladdrr:::.table_remove_column(ptr, 99), "Failed to remove column")
  expect_error(pladdrr:::.table_insert_column(ptr, 99, "z"), "Failed to insert column")
})

# --- RTable module (src/modules/table_module.cpp) methods reached only via
# the raw `.cpp` field ------------------------------------------------------
# table-wrapper.R's .table_methods dispatch table wires most Table R6
# methods straight to the RTable Rcpp module, but its statistics
# (get_mean/get_stdev/get_minimum/get_maximum/get_sum/get_quantile),
# as_matrix, as_data_frame, get_info, remove_row, and remove_column are
# never called from R -- the R6 API uses the separate bare .table_* Rcpp
# exports (or omits them, for remove_row/remove_column) instead. They are
# still reachable directly through the `.cpp` field, which $.Table exposes
# like any other list element.

test_that("Table() creates an RTable module usable directly via $.cpp", {
  tbl <- Table(numberOfRows = 2, columnNames = c("x", "y"))
  expect_s4_class(tbl$.cpp, "Rcpp_RTable")
})

test_that("RTable module get_mean/get_stdev/get_minimum/get_maximum/get_sum/get_quantile work via $.cpp", {
  tbl <- Table(numberOfRows = 3, columnNames = "x")
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(2, "x", 2)
  tbl$set_numeric_value(3, "x", 3)

  expect_equal(tbl$.cpp$get_mean(1), 2)
  expect_equal(tbl$.cpp$get_stdev(1), sd(c(1, 2, 3)))
  expect_equal(tbl$.cpp$get_minimum(1), 1)
  expect_equal(tbl$.cpp$get_maximum(1), 3)
  expect_equal(tbl$.cpp$get_sum(1), 6)
  expect_equal(tbl$.cpp$get_quantile(1, 0.5), 2)
})

test_that("RTable module statistics return NA (not an error) for an out-of-range column via $.cpp", {
  # Verified interactively: unlike the bare .table_get_mean() etc. exports,
  # the RTable module versions catch the same MelderError and return
  # NA_REAL rather than raising -- this is a genuine, safe behavioral
  # difference between the two implementations, not a copy-paste no-op.
  tbl <- Table(numberOfRows = 2, columnNames = "x")
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(2, "x", 2)

  expect_true(is.na(tbl$.cpp$get_mean(99)))
  expect_true(is.na(tbl$.cpp$get_stdev(99)))
  expect_true(is.na(tbl$.cpp$get_minimum(99)))
  expect_true(is.na(tbl$.cpp$get_maximum(99)))
  expect_true(is.na(tbl$.cpp$get_sum(99)))
  expect_true(is.na(tbl$.cpp$get_quantile(99, 0.5)))
})

test_that("RTable module remove_row/remove_column work via $.cpp (not wired into Table()'s methods)", {
  tbl <- Table(numberOfRows = 2, columnNames = c("x", "y"))
  tbl$.cpp$remove_column(2)
  expect_equal(tbl$get_number_of_columns(), 1)

  tbl$.cpp$remove_row(1)
  expect_equal(tbl$get_number_of_rows(), 1)
})

test_that("RTable module remove_row/remove_column/insert_row/insert_column/set_column_label error on out-of-range index via $.cpp", {
  tbl <- Table(numberOfRows = 2, columnNames = c("x", "y"))
  expect_error(tbl$.cpp$remove_row(99), "Failed to remove row")
  expect_error(tbl$.cpp$remove_column(99), "Failed to remove column")
  expect_error(tbl$.cpp$insert_row(99), "Failed to insert row")
  expect_error(tbl$.cpp$insert_column(99, "z"), "Failed to insert column")
  expect_error(tbl$.cpp$set_column_label(99, "z"), "Failed to set column label")
})

test_that("Table insert_column adds a column via the R6 method (never exercised by other tests)", {
  tbl <- Table(numberOfRows = 2, columnNames = "x")
  tbl$insert_column(1, "y")
  expect_equal(tbl$get_number_of_columns(), 2)
  expect_equal(tbl$get_column_label(1), "y")
})

test_that("Table get_column_label errors on an out-of-range column number", {
  tbl <- Table(numberOfRows = 1, columnNames = "x")
  expect_error(tbl$get_column_label(99), "Column number out of range")
})

test_that("Table save errors on an unwritable path", {
  # Verified interactively: Data_writeToTextFile() throws a MelderError for
  # a directory that does not exist, which RTable::save() catches and
  # re-raises as a plain R error -- no crash risk.
  tbl <- Table(numberOfRows = 1, columnNames = "x")
  expect_error(
    tbl$save(file.path(tempdir(), "pladdrr-does-not-exist-xyz", "out.Table")),
    "Failed to save Table"
  )
})

test_that("RTable module as_matrix/as_data_frame/get_info work via $.cpp", {
  tbl <- Table(numberOfRows = 2, columnNames = c("x", "y"))
  tbl$set_numeric_value(1, "x", 1)
  tbl$set_numeric_value(1, "y", 2)
  tbl$set_numeric_value(2, "x", 3)
  tbl$set_numeric_value(2, "y", 4)

  mat <- tbl$.cpp$as_matrix()
  expect_equal(as.numeric(mat), c(1, 3, 2, 4))

  df <- tbl$.cpp$as_data_frame()
  expect_equal(dim(df), c(2, 2))

  info <- tbl$.cpp$get_info()
  expect_equal(info$n_rows, 2)
  expect_equal(info$n_columns, 2)
  expect_equal(info$column_names, c("x", "y"))
})

# --- table_module.cpp's module-level factory functions ---------------------
# Table_create/Table_create_with_column_names/Table_from_data_frame are
# registered on the table_module Rcpp Module but Table()'s constructor uses
# the separate bare .table_create()/.table_create_with_column_names()
# exports instead, so these are unreachable except by pulling the module
# out directly, the same way R/table-wrapper.R itself does internally.

test_that("table_module's Table_create/Table_create_with_column_names/Table_from_data_frame work directly", {
  mod <- pladdrr:::get_module("table_module")

  ptr1 <- mod$Table_create(2, 3)
  tbl1 <- Table(.xptr = ptr1)
  expect_equal(tbl1$get_number_of_rows(), 2)
  expect_equal(tbl1$get_number_of_columns(), 3)

  ptr2 <- mod$Table_create_with_column_names(2, c("a", "b"))
  tbl2 <- Table(.xptr = ptr2)
  expect_equal(tbl2$get_column_names(), c("a", "b"))

  # Exercises all three data.frame column-type branches (integer, string,
  # double) inside Module_Table_from_data_frame() in one call.
  df <- data.frame(a = 1:2, b = c("cat", "dog"), c = c(1.5, 2.5),
                    stringsAsFactors = FALSE)
  ptr3 <- mod$Table_from_data_frame(df)
  tbl3 <- Table(.xptr = ptr3)
  expect_equal(tbl3$get_number_of_rows(), 2)
  expect_equal(tbl3$get_number_of_columns(), 3)
  out <- tbl3$as_data_frame()
  expect_equal(out$a, c(1, 2))
  expect_equal(out$b, c("cat", "dog"))
  expect_equal(out$c, c(1.5, 2.5))
})
