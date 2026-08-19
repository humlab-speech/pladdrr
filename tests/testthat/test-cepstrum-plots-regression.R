# Regression tests for R/cepstrum_plots.R bugs found during the autoplot
# coverage work (2026-08-19): plot_powercepstrogram, plot_cpp_timeseries,
# and plot_powercepstrum all independently hand-rolled matrix->data-frame
# conversion with hardcoded placeholder axis ranges (max_time <- 5.0,
# max_quefrency <- 0.05) instead of the object's real values, and two of
# the three skipped the raw-power-to-dB conversion entirely. None of these
# 4 functions had any prior test coverage.

library(testthat)
library(pladdrr)

test_that("plot_powercepstrogram uses the cepstrogram's real time range, not a hardcoded placeholder", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_powercepstrogram(cepstrogram)
  expect_s3_class(p, "ggplot")
  # Real duration for this fixture is ~0.25s; the placeholder was 5.0s.
  expect_lt(max(p$data$time), 1.0)
  expect_gt(max(p$data$time), 0.1)
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

test_that("plot_cpp_timeseries uses the cepstrogram's real time range, not a hardcoded placeholder", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_cpp_timeseries(cepstrogram, n_samples = 20)
  expect_s3_class(p, "ggplot")
  # Default time_range should span the real ~0.25s duration, not 0-5s.
  expect_lt(max(p$data$time), 1.0)
})

test_that("plot_cpp_timeseries drops failed samples as NA, not silent zeros", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  # qmin = -1 makes every get_cpp_at_time() call error (verified directly:
  # cepstrogram$get_cpp_at_time(time = 0.1, qmin = -1, qmax = 0) throws
  # "Failed to get CPP at time"). With the tryCatch scoping bug, the
  # error handler's `cpp_values[i] <- NA` only touches a copy of
  # cpp_values local to the handler closure, so the outer cpp_values
  # keeps its numeric(n_samples) default of 0 for every sample, and the
  # NA-filter downstream never removes them — 5 rows all showing cpp = 0
  # instead of 0 rows.
  p <- plot_cpp_timeseries(cepstrogram, time_range = c(0, 0.2), qmin = -1, n_samples = 5)
  expect_equal(nrow(p$data), 0)
})

test_that("plot_powercepstrum uses the cepstrum's real quefrency range, not a hardcoded placeholder", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrum <- sound$to_cepstrum()$to_power_cepstrum()

  p <- plot_powercepstrum(cepstrum, show_peak = FALSE, show_trendline = FALSE)
  expect_s3_class(p, "ggplot")
  # Real quefrency range for this fixture is ~0.256s; the placeholder was 0.05s.
  expect_gt(max(p$data$quefrency), 0.1)
})

test_that("plot_powercepstrum converts power to dB, matching the peak marker's own dB scale", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  cepstrum <- sound$to_cepstrum()$to_power_cepstrum()

  p <- plot_powercepstrum(cepstrum, show_peak = FALSE, show_trendline = FALSE)
  # Raw linear power for this fixture spans ~3e-4 to ~1.5e11; a correct dB
  # conversion brings the line trace into the same rough range as
  # get_value_at_quefrency(unit = "dB") (tens to low hundreds of dB), not
  # spanning 11+ orders of magnitude.
  expect_true(all(p$data$power_db > -200 & p$data$power_db < 200))
})
