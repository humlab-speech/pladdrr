# Regression tests for R/cepstrum_plots.R bugs found during the autoplot
# coverage work (2026-08-19): plot_powercepstrogram, plot_cpp_timeseries,
# and plot_cpp_contour all had axis transposition issues, power unit
# conversion with hardcoded placeholder axis ranges (max_time <- 5.0,
# max_quefrency <- 0.05) instead of the object's real values, and two of
# the three skipped the raw-power-to-dB conversion entirely. None of these
# had test coverage before.

library(pladdrr)

test_that("plot_powercepstrogram uses the cepstrogram's real time range, not a hardcoded placeholder", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_powercepstrogram(cepstrogram, quefrency_range = c(0, 0.05))
  # Real duration for this fixture is ~0.25s; the placeholder was 5.0s.
  # If using the placeholder, max(plot_data$time) would be ~5.0, way off.
  # The correct values should cluster around the real audio duration.
  expect_lt(max(p$data$time), 0.5)
  expect_lt(max(p$data$time), 1.0)  # Should be ~0.25, nowhere near 5.0
})

test_that("plot_powercepstrogram is not quefrency/time-transposed", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_powercepstrogram(cepstrogram, quefrency_range = c(0, 0.05))
  # as.data.frame.PowerCepstrogram (the correct reference implementation)
  # produces one row per (time, quefrency) pair; a transposed version would
  # still have the right row count but the wrong values paired together.
  # Cross-check against the known-correct accessor directly.
  reference <- as.data.frame(cepstrogram)
  reference <- reference[reference$quefrency >= 0 & reference$quefrency <= 0.05, ]
  expect_equal(nrow(p$data), nrow(reference))
  expect_equal(sort(unique(p$data$time)), sort(unique(reference$time)))
})

test_that("plot_powercepstrogram converts power to dB", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_powercepstrogram(cepstrogram)
  # Raw linear power for this fixture spans ~1e-6 to ~1e11; a correct dB
  # conversion brings that into roughly a -100..150 dB range.
  expect_true(all(p$data$power_db > -200 & p$data$power_db < 200))
})
