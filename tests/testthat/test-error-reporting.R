# Typed-error contract (design principle 6).
#
# Locks in the convention from src/pladdrr_errors.h + R/error-classes.R:
#   - tagged C++ errors become classed R conditions
#   - data-loss warnings attach attr(., "pladdrr_data_loss")
# Routines that have NOT been retrofitted yet are exempt; the test only checks
# the wrappers explicitly listed below. Extend the list as wrappers are
# migrated.

library(testthat)

skip_if_not_installed("pladdrr")

retrofitted <- c(
  "formant_get_multiple_formants_at_times",
  "pitch_get_strengths_at_times"
)

test_that("tag parser is round-trip clean", {
  parse <- pladdrr:::.parse_pladdrr_tag
  msg <- "[pladdrr_input_error:foo_bar:baz] something is wrong"
  res <- parse(msg)
  expect_equal(res$class, "pladdrr_input_error")
  expect_equal(res$routine, "foo_bar")
  expect_equal(res$param, "baz")
  expect_equal(res$message, "something is wrong")

  expect_null(parse("this is an untagged error"))
})

test_that("with_pladdrr_errors reclassifies tagged errors", {
  err <- tryCatch(
    with_pladdrr_errors(
      stop("[pladdrr_input_error:probe:p1] bad p1")
    ),
    pladdrr_input_error = function(e) e
  )
  expect_s3_class(err, "pladdrr_input_error")
  expect_s3_class(err, "pladdrr_error")
  expect_equal(err$routine, "probe")
  expect_equal(err$param, "p1")
  expect_equal(conditionMessage(err), "bad p1")
})

test_that("with_pladdrr_errors passes through untagged errors", {
  expect_error(
    with_pladdrr_errors(stop("plain old error")),
    "plain old error"
  )
})

test_that("with_pladdrr_errors attaches data-loss attribute on tagged warning", {
  res <- suppressWarnings(with_pladdrr_errors({
    warning("[pladdrr_data_loss:probe:-] 3 of 5 values undefined")
    c(1, 2, 3, NA, NA)
  }))
  loss <- attr(res, "pladdrr_data_loss")
  expect_false(is.null(loss))
  expect_equal(loss[[1]]$routine, "probe")
  expect_match(loss[[1]]$message, "3 of 5")
})

test_that("retrofitted formant wrapper raises classed input error on null xptr", {
  skip_if_not("formant_get_multiple_formants_at_times" %in% retrofitted)
  skip_if_not(exists("formant_get_multiple_formants_at_times",
                     envir = asNamespace("pladdrr"), inherits = FALSE),
              "internal export not present")
  fn <- get("formant_get_multiple_formants_at_times",
            envir = asNamespace("pladdrr"))
  null_ptr <- methods::new("externalptr")
  err <- tryCatch(
    with_pladdrr_errors(fn(null_ptr, times = 0.1, formant_numbers = 1L)),
    pladdrr_input_error = function(e) e,
    error = function(e) e
  )
  expect_s3_class(err, "pladdrr_input_error")
  expect_equal(err$routine, "formant_get_multiple_formants_at_times")
  expect_equal(err$param, "formant_xptr")
})

test_that("options(pladdrr.data_loss=) controls reaction to data loss", {
  loss_expr <- quote(with_pladdrr_errors({
    warning("[pladdrr_data_loss:probe:-] 3 of 5 values undefined")
    "result"
  }))

  withr_opts <- options(pladdrr.data_loss = "error")
  on.exit(options(withr_opts), add = TRUE)
  expect_error(eval(loss_expr), class = "pladdrr_data_loss")

  options(pladdrr.data_loss = "silent")
  expect_silent(res <- eval(loss_expr))
  expect_length(attr(res, "pladdrr_data_loss"), 1L)

  options(pladdrr.data_loss = "warn")
  expect_warning(eval(loss_expr), class = "pladdrr_data_loss")
})
