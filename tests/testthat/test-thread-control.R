# test-thread-control.R - Tests for R/thread-control.R (pladdrr_threads)

test_that("pladdrr_threads() with no args just queries current state", {
  state <- pladdrr_threads()
  expect_type(state, "list")
  expect_true(
    all(
      c("processors", "enabled", "max_threads",
        "min_elements_per_thread") %in% names(state)))
  expect_gte(state$processors, 1)
})

test_that("pladdrr_threads(1) disables multithreading", {
  old <- pladdrr_threads()
  on.exit(pladdrr_threads(0))

  state <- pladdrr_threads(1)
  expect_false(state$enabled)
  expect_equal(state$max_threads, 1L, tolerance = sqrt(.Machine$double.eps))
})

test_that("pladdrr_threads(0) restores automatic (all-core) mode", {
  pladdrr_threads(1)
  state <- pladdrr_threads(0)

  expect_true(state$enabled)
  expect_gte(state$max_threads, 1L)
})

test_that("pladdrr_threads rejects invalid n", {
  expect_error(pladdrr_threads(-1), "non-negative integer")
  expect_error(pladdrr_threads(c(1, 2)), "non-negative integer")
  expect_error(pladdrr_threads(NA), "non-negative integer")

  pladdrr_threads(0)
})
