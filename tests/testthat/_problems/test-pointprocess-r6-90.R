# Extracted from test-pointprocess-r6.R:90

# test -------------------------------------------------------------------------
s <- generate_sine_wave(150, 0.3, sampling_rate = 16000)
pitch <- s$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 600)
pp <- suppressWarnings(pitch$to_point_process())
n_periods <- pp$get_number_of_periods(0, 0)
expect_gt(n_periods, 0)
expect_true(is.finite(pp$get_mean_period(0, 0)))
expect_true(is.finite(pp$get_stdev_period(0, 0)))
expect_equal(pp$get_voice_breaks(0, 0), 0,
  tolerance = sqrt(.Machine$double.eps))
pp2 <- PointProcess(0, 1)
pp2$add_point(0.1)
pp2$add_point(0.2)
pp2$add_point(0.3)
expect_identical(
  pp2$get_number_of_periods(0L, 0, period_floor = 0.0001,
    period_ceiling = 0.02), 0)
