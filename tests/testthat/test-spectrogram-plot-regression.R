# tests/testthat/test-spectrogram-plot-regression.R
# Regression tests for the Spectrogram frequency-axis transposition and
# missing power->dB conversion bugs found during the autoplot coverage
# work (2026-08-19): autoplot.Spectrogram/autolayer.Spectrogram and
# plot.Spectrogram all independently hand-rolled expand.grid(time=,
# frequency=) + as.vector(mat), which only agrees with as.vector's
# column-major order when the matrix happens to be square. A 220 Hz tone
# rendered with the peak at 2201 Hz before the fix.

library(testthat)
library(pladdrr)

test_that("autoplot.Spectrogram renders the frequency axis correctly, not transposed", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()

  p <- ggplot2::autoplot(spectrogram)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "frequency", "power_db") %in% names(p$data)))

  peak_row <- p$data[which.max(p$data$power_db), ]
  expect_lt(abs(peak_row$frequency - 220), 50)
})

test_that("autoplot.Spectrogram converts power to dB (dynamic_range is not a no-op)", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()

  p <- ggplot2::autoplot(spectrogram, dynamic_range = 20)
  # Raw linear power for this fixture spans ~1e-17 to ~15; if dynamic_range
  # were being applied to unconverted linear values, every value would
  # still be numerically > (max - 20) and nothing would be clipped. With a
  # correct dB conversion and dynamic_range = 20, most bins should clip.
  clipped_floor <- max(p$data$power_db) - 20
  expect_gt(mean(p$data$power_db == clipped_floor), 0.5)
})

test_that("autolayer.Spectrogram matches autoplot.Spectrogram's data", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()

  p <- ggplot2::ggplot() + ggplot2::autolayer(spectrogram)
  expect_s3_class(p, "ggplot")
  layer_data <- p$layers[[1]]$data
  peak_row <- layer_data[which.max(layer_data$power_db), ]
  expect_lt(abs(peak_row$frequency - 220), 50)
})

test_that("plot.Spectrogram renders the frequency axis correctly, not transposed", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()

  p <- plot(spectrogram)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "frequency", "power_db") %in% names(p$data)))

  peak_row <- p$data[which.max(p$data$power_db), ]
  expect_lt(abs(peak_row$frequency - 220), 50)
})

test_that("plot.Spectrogram converts power to dB (dynamic_range is not a no-op)", {
  sound <- generate_sine_wave(220, 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()

  p <- plot(spectrogram, dynamic_range = 20)
  clipped_floor <- max(p$data$power_db) - 20
  expect_gt(mean(p$data$power_db == clipped_floor), 0.5)
})
