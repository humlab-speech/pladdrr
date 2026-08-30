# test-datatable-utils.R - Tests for R/datatable-utils.R (internal helpers)

test_that("ensure_datatable converts a data.frame in place and is idempotent", {
  df <- data.frame(x = 1:3, y = c("a", "b", "c"), stringsAsFactors = FALSE)
  out <- pladdrr:::ensure_datatable(df)
  expect_true(data.table::is.data.table(out))

  already_dt <- data.table::data.table(x = 1)
  out2 <- pladdrr:::ensure_datatable(already_dt)
  expect_true(data.table::is.data.table(out2))
})

test_that("df_to_dt copies without modifying the original", {
  df <- data.frame(x = 1:3)
  dt <- pladdrr:::df_to_dt(df)

  expect_true(data.table::is.data.table(dt))
  expect_false(data.table::is.data.table(df))
})

test_that("dt_empty creates a zero-row data.table with typed columns", {
  dt <- pladdrr:::dt_empty(time = numeric(), formant = integer(), label = character())
  expect_true(data.table::is.data.table(dt))
  expect_equal(nrow(dt), 0)
  expect_type(dt$time, "double")
  expect_type(dt$formant, "integer")
  expect_type(dt$label, "character")
})

test_that("dt_rbindlist binds a list of rows and fills missing columns", {
  rows <- list(list(x = 1, y = 2), list(x = 3))
  dt <- pladdrr:::dt_rbindlist(rows, fill = TRUE)

  expect_equal(nrow(dt), 2)
  expect_true(is.na(dt$y[2]))
})

test_that("dt_setkey sets a key on the data.table by reference", {
  dt <- data.table::data.table(time = c(3, 1, 2), value = c("c", "a", "b"))
  out <- pladdrr:::dt_setkey(dt, time)

  expect_identical(data.table::key(dt), "time")
  expect_identical(out, dt)
})

test_that("dt_create builds a data.table from named vectors and applies a key", {
  dt <- pladdrr:::dt_create(time = c(2, 1), value = c(20, 10), key = "time")

  expect_true(data.table::is.data.table(dt))
  expect_identical(data.table::key(dt), "time")

  dt_nokey <- pladdrr:::dt_create(x = 1:3)
  expect_null(data.table::key(dt_nokey))
})

test_that(".finalize_dataframe returns the data.table unchanged by default", {
  dt <- data.table::data.table(x = 1:3)
  out <- pladdrr:::.finalize_dataframe(dt)
  expect_true(data.table::is.data.table(out))
})

test_that(".finalize_dataframe converts to data.frame and warns once when opted out", {
  old <- getOption("pladdrr.return_datatable")
  on.exit(options(pladdrr.return_datatable = old))
  options(pladdrr.return_datatable = FALSE)

  dt <- data.table::data.table(x = 1:3)
  expect_warning(out <- pladdrr:::.finalize_dataframe(dt), "deprecated")
  expect_false(data.table::is.data.table(out))
  expect_s3_class(out, "data.frame")

  # Warning only fires once per session
  expect_no_warning(pladdrr:::.finalize_dataframe(dt))
})
