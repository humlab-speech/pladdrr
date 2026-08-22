test_that("calculate_cpps_fast and calculate_cpps_ultra produce matching results", {

  wav <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(wav), "Test audio not found")
  sound <- Sound(wav)

  # Use identical parameters for both
  cpps_fast <- calculate_cpps_fast(sound,
    subtract_tilt = TRUE,
    time_averaging_window = 0.001,
    quefrency_averaging_window = 0.0005,
    pitch_floor = 60,
    pitch_ceiling = 333.3,
    trend_line_type = "straight",
    fit_method = "robust"
  )

  cpps_ultra <- calculate_cpps_ultra(sound,
    subtract_trend = TRUE,
    time_averaging_window = 0.001,
    quefrency_averaging_window = 0.0005,
    pitch_floor = 60,
    pitch_ceiling = 333.3,
    line_type = "straight",
    fit_method = "robust"
  )

  expect_true(is.numeric(cpps_fast))
  expect_true(is.numeric(cpps_ultra))
  expect_true(is.finite(cpps_fast))
  expect_true(is.finite(cpps_ultra))

  # Should match within 0.1 dB
  expect_equal(cpps_fast, cpps_ultra, tolerance = 0.1)
})

test_that("PowerCepstrum get_peak_prominence accepts Praat-style trend fit without warning", {
  wav <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(wav), "Test audio not found")

  sound <- Sound(wav)
  cepstrum <- sound$to_spectrum()$to_power_cepstrum()

  cpp <- expect_no_warning(
    cepstrum$get_peak_prominence(
      60, 333.3, "parabolic", 0.001, 0.05, "exponential decay", "robust slow"
    )
  )

  expect_true(is.numeric(cpp))
  expect_true(is.finite(cpp))
})

test_that("calculate_cpps_ultra exercises the time-smoothing pass when time_averaging_window spans multiple cepstrogram frames", {
  # PowerCepstrogram_smooth_fast()'s time-averaging pass is a no-op whenever
  # floor(time_averaging_window / time_step) <= 1. Every other CPPS test in
  # this suite uses the R6-matching default (time_averaging_window = 0.001,
  # time_step = 0.002 -> floor(0.5) = 0), which never takes that branch. The
  # historical AVQI/get_cpps_fast() default (0.01) with the same time_step
  # gives floor(5) = 5, actually exercising the threaded smoothing pass.
  wav <- system.file("signalfiles/DSI/input/fh1.wav", package = "pladdrr")
  skip_if(!file.exists(wav), "Test audio not found")
  sound <- Sound(wav)

  cpps_no_smoothing <- calculate_cpps_ultra(sound, time_averaging_window = 0.001, time_step = 0.002)
  cpps_with_smoothing <- calculate_cpps_ultra(sound, time_averaging_window = 0.01, time_step = 0.002)

  expect_true(is.numeric(cpps_with_smoothing))
  expect_true(is.finite(cpps_with_smoothing))
  # Different smoothing window -> a (verified, not merely assumed) different
  # CPPS value, confirming the smoothing pass actually ran.
  expect_false(isTRUE(all.equal(cpps_no_smoothing, cpps_with_smoothing)))
})

test_that("PowerCepstrum get_peak_prominence validates trend fit", {
  wav <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  skip_if(!file.exists(wav), "Test audio not found")

  sound <- Sound(wav)
  cepstrum <- sound$to_spectrum()$to_power_cepstrum()

  expect_error(
    cepstrum$get_peak_prominence(trend_type = "straight", fit_method = "bogus"),
    "should be one of"
  )
})
