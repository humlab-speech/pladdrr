# tests/testthat/test-validators-unit.R
# Unit tests for R/validators.R — the shared argument validators that raise
# classed `pladdrr_input_error` conditions at wrapper entry. Previously only
# the pitch-range path was exercised indirectly (test-validators.R); these
# cover the count/number/quefrency/time-step/trend-fit validators directly.

test_that(
  ".check_pitch_range accepts valid ranges and rejects inverted/non-positive", {
  expect_invisible(pladdrr:::.check_pitch_range(75, 600))
  expect_error(pladdrr:::.check_pitch_range(600, 75),
    class = "pladdrr_input_error")
  expect_error(pladdrr:::.check_pitch_range(-10, 600),
    class = "pladdrr_input_error")
  expect_error(pladdrr:::.check_pitch_range(75, 75),
    class = "pladdrr_input_error")
})

test_that(".check_positive_count rejects values below 1", {
  expect_invisible(pladdrr:::.check_positive_count(3, "n_formants"))
  expect_error(pladdrr:::.check_positive_count(0, "n_formants"),
    class = "pladdrr_input_error")
  expect_error(pladdrr:::.check_positive_count(-1, "n_formants"),
    class = "pladdrr_input_error")
})

test_that(".check_positive_number rejects non-positive values", {
  expect_invisible(pladdrr:::.check_positive_number(0.01, "time_step"))
  expect_error(pladdrr:::.check_positive_number(0, "x"),
    class = "pladdrr_input_error")
  expect_error(pladdrr:::.check_positive_number(NA_real_, "x"),
    class = "pladdrr_input_error")
})

test_that(".check_quefrency_range handles autowindow and reversed ranges", {
  expect_invisible(pladdrr:::.check_quefrency_range(0.001, 0.04))
  # qend == 0 means "autowindow" and is accepted.
  expect_invisible(pladdrr:::.check_quefrency_range(0.001, 0))
  # qend <= qstart (and qend != 0) is a reversed range -> error.
  expect_error(pladdrr:::.check_quefrency_range(0.04, 0.001),
    class = "pladdrr_input_error")
  expect_error(pladdrr:::.check_quefrency_range(-1, 0.04),
    class = "pladdrr_input_error")
})

test_that(".check_time_step accepts 0 (auto) and rejects negative", {
  expect_invisible(pladdrr:::.check_time_step(0))
  expect_invisible(pladdrr:::.check_time_step(0.01))
  expect_error(pladdrr:::.check_time_step(-1), class = "pladdrr_input_error")
})

test_that(
  ".check_trend_fit_method accepts deterministic methods and warns on robust slow", {
  expect_invisible(pladdrr:::.check_trend_fit_method("robust"))
  expect_invisible(pladdrr:::.check_trend_fit_method("least_squares"))
  expect_warning(pladdrr:::.check_trend_fit_method("robust slow"),
    "robust slow")
})
