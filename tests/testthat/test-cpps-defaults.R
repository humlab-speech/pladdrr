test_that("calculate_cpps_fast() formals match the r6 profile in .cpps_profiles", {
  p <- pladdrr:::.cpps_profiles$r6
  f <- formals(calculate_cpps_fast)
  expect_equal(f$subtract_tilt, p$subtract_tilt)
  expect_equal(f$time_averaging_window, p$time_averaging_window)
  expect_equal(f$quefrency_averaging_window, p$quefrency_averaging_window)
  expect_equal(f$pitch_floor, p$pitch_floor)
  expect_equal(f$pitch_ceiling, p$pitch_ceiling)
  expect_equal(f$qstart_fit, p$qstart_fit)
  expect_equal(f$qend_fit, p$qend_fit)
  expect_equal(f$trend_line_type, p$trend_line_type)
  expect_equal(f$fit_method, p$fit_method)
  expect_equal(f$interpolation, p$interpolation)
  expect_equal(f$delta_f0, p$delta_f0)
  expect_equal(f$time_step, 0.002)
  expect_equal(f$max_frequency, 5000)
  expect_equal(f$pre_emphasis_from, 50)
})

test_that("PowerCepstrogram$get_cpps defaults match the r6 profile", {
  p <- pladdrr:::.cpps_profiles$r6
  f <- formals(pladdrr:::.powercepstrogram_methods$get_cpps)
  expect_equal(f$subtract_tilt, p$subtract_tilt)
  expect_equal(f$time_averaging_window, p$time_averaging_window)
  expect_equal(f$quefrency_averaging_window, p$quefrency_averaging_window)
  expect_equal(f$pitch_floor, p$pitch_floor)
  expect_equal(f$pitch_ceiling, p$pitch_ceiling)
  expect_equal(f$delta_f0, p$delta_f0)
  expect_equal(f$quefrency_range_start, p$qstart_fit)
  expect_equal(f$quefrency_range_end, p$qend_fit)
  expect_equal(eval(f$interpolation)[1], p$interpolation)
  expect_equal(eval(f$trend_line_type)[1], p$trend_line_type)
  expect_equal(eval(f$fit_method)[1], p$fit_method)
})

test_that("get_cpps_fast() formals match the avqi profile", {
  p <- pladdrr:::.cpps_profiles$avqi
  f <- formals(get_cpps_fast)
  expect_equal(f$subtract_tilt, p$subtract_tilt)
  expect_equal(f$time_averaging_window, p$time_averaging_window)
  expect_equal(f$quefrency_averaging_window, p$quefrency_averaging_window)
  expect_equal(f$pitch_floor, p$pitch_floor)
  expect_equal(f$pitch_ceiling, p$pitch_ceiling)
  expect_equal(f$delta_f0, p$delta_f0)
  expect_equal(f$qstart_fit, p$qstart_fit)
  expect_equal(f$qend_fit, p$qend_fit)
  expect_equal(f$interpolation, p$interpolation)
  expect_equal(f$trend_line_type, p$trend_line_type)
  expect_equal(f$fit_method, p$fit_method)
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
