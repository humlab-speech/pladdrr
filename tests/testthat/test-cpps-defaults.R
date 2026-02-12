test_that("calculate_cpps_fast() formals match documented defaults", {
  f <- formals(calculate_cpps_fast)
  expect_equal(f$subtract_tilt, TRUE)
  expect_equal(f$time_averaging_window, 0.001)
  expect_equal(f$quefrency_averaging_window, 0.0005)
  expect_equal(f$pitch_floor, 60)
  expect_equal(f$pitch_ceiling, 333.3)
  expect_equal(f$qstart_fit, 0.003)
  expect_equal(f$qend_fit, 0.04)
  expect_equal(f$trend_line_type, "straight")
  expect_equal(f$fit_method, "robust")
  expect_equal(f$interpolation, "parabolic")
  expect_equal(f$delta_f0, 0.05)
  expect_equal(f$time_step, 0.002)
  expect_equal(f$max_frequency, 5000)
  expect_equal(f$pre_emphasis_from, 50)
})

test_that("calculate_cpps_ultra() formals match documented defaults", {
  f <- formals(calculate_cpps_ultra)
  expect_equal(f$time_averaging_window, 0.001)
  expect_equal(f$quefrency_averaging_window, 0.0005)
  expect_equal(f$pitch_floor, 60)
  expect_equal(f$pitch_ceiling, 333.3)
  expect_equal(f$subtract_trend, TRUE)
  expect_equal(f$line_type, "straight")
  expect_equal(f$fit_method, "robust")
  expect_equal(f$interpolation, "parabolic")
  expect_equal(f$time_step, 0.002)
  expect_equal(f$max_quefrency, 0.05)
  expect_equal(f$tolerance, 0.05)
  expect_equal(f$tilt_line_quefrency, 0.001)
  expect_equal(f$pre_emphasis_from, 50)
  expect_equal(f$max_frequency, 5000)
})

test_that("calculate_cpps_fast and calculate_cpps_ultra share matching defaults", {
  fast <- formals(calculate_cpps_fast)
  ultra <- formals(calculate_cpps_ultra)

  # These parameters exist in both and must match
  shared_params <- c("time_averaging_window", "quefrency_averaging_window",
                     "pitch_floor", "pitch_ceiling", "interpolation",
                     "fit_method", "time_step", "max_frequency", "pre_emphasis_from")
  for (p in shared_params) {
    expect_equal(fast[[p]], ultra[[p]],
                 info = paste0("Mismatch in shared param '", p, "'"))
  }
})
