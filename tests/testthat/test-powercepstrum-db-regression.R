# tests/testthat/test-powercepstrum-db-regression.R
# Regression tests for the v5.0.4 follow-up plotting fixes (2026-08-19).
#
# The two remaining PowerCepstrum call sites that still plotted raw linear
# power under a "Power (dB)" axis — autoplot.PowerCepstrum /
# autolayer.PowerCepstrum (R/autoplot-methods.R) and plot.PowerCepstrum
# (R/plotting-methods.R) — now convert the misleadingly-named "power_dB"
# column (raw linear power from the C++ as_data_frame()) to a real dB
# "power_db" column before plotting. Also covered: plot_cpp_timeseries'
# all-samples-failed "NaN dB" subtitle, and plot_powercepstrogram's
# show_cpp_contour overlay (previously a flat quefrency = 0.01 placeholder).

test_that("autoplot.PowerCepstrum plots real dB, not raw linear power", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5)
  pc <- sound$to_spectrum()$to_power_cepstrum()

  p <- ggplot2::autoplot(pc)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("quefrency", "power_dB", "power_db") %in% names(p$data)))

  # power_db is the explicit dB conversion of the raw linear power_dB column.
  expect_equal(p$data$power_db, 10 * log10(pmax(p$data$power_dB, 1e-20)))
  # Raw linear power spans many orders of magnitude; real dB is bounded.
  expect_true(all(p$data$power_db > -200 & p$data$power_db < 200))
})

test_that("autolayer.PowerCepstrum layer data is real dB", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5)
  pc <- sound$to_spectrum()$to_power_cepstrum()

  p <- ggplot2::ggplot() + ggplot2::autolayer(pc)
  expect_s3_class(p, "ggplot")

  layer_data <- p$layers[[1]]$data
  expect_true(all(c("quefrency", "power_dB", "power_db") %in% names(layer_data)))
  expect_equal(layer_data$power_db, 10 * log10(pmax(layer_data$power_dB, 1e-20)))
})

test_that("plot.PowerCepstrum plots real dB, not raw linear power", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5)
  pc <- sound$to_spectrum()$to_power_cepstrum()

  p <- plot(pc)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("quefrency", "power_dB", "power_db") %in% names(p$data)))

  expect_equal(p$data$power_db, 10 * log10(pmax(p$data$power_dB, 1e-20)))
  expect_true(all(p$data$power_db > -200 & p$data$power_db < 200))
})

test_that("plot_cpp_timeseries shows 'No samples' subtitle when all CPP samples fail", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  # qmin = -1 makes every get_cpp_at_time() call error, so plot_data ends
  # up with zero rows after NA filtering. The old code then computed
  # mean()/sd() on the empty cpp vector, producing a cosmetic
  # "Mean CPP: NaN dB (SD: NA)" subtitle.
  p <- plot_cpp_timeseries(cepstrogram, n_samples = 20, qmin = -1, qmax = 0)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$subtitle, "No samples")
})

test_that("plot_powercepstrogram contour tracks the real cepstral peak, not a flat placeholder", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5)
  cepstrogram <- sound$to_powercepstrogram(pitch_floor = 60, time_step = 0.002)

  p <- plot_powercepstrogram(cepstrogram, show_cpp_contour = TRUE,
                             quefrency_range = c(0.001, 0.02))
  expect_s3_class(p, "ggplot")

  # The contour layer carries only time + quefrency (the heatmap layer also
  # has power/power_db).
  contour_layer <- Find(function(l) all(c("time", "quefrency") %in% names(l$data)) &&
                          !"power_db" %in% names(l$data), p$layers)
  expect_false(is.null(contour_layer))

  qs <- contour_layer$data$quefrency
  expect_true(all(qs > 0))
  # Old bug hardcoded every quefrency to 0.01 regardless of the data; a
  # 220 Hz tone's cepstral peak is ~0.0045 s, so not every value is 0.01.
  expect_false(all(abs(qs - 0.01) < 1e-6))
  # Physical sanity: the peak sits below the old 0.01 placeholder and above 0.
  expect_gt(median(qs), 0.002)
  expect_lt(median(qs), 0.01)
})
