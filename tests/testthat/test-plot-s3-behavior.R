# tests/testthat/test-plot-s3-behavior.R
# Behavioral coverage for the base-plot S3 methods (R/plotting-methods.R) and
# the remaining untested branches of R/cepstrum_plots.R. The S3 methods
# previously only had an existence check (test-s3-method-coverage.R); these
# tests assert they actually render a ggplot with the expected data columns
# and exercise the show_peak/show_trendline/smooth/reference_lines branches.

fixture_sound <- function() {
  Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
}

test_that("plot.Sound renders a ggplot with time/value columns", {
  p <- plot(fixture_sound())
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "value") %in% names(p$data)))
})

test_that("plot.Pitch renders a ggplot with time/frequency columns", {
  pitch <- fixture_sound()$to_pitch()
  p <- plot(pitch)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "frequency") %in% names(p$data)))
  # show_voicing = FALSE exercises the non-voicing branch
  p2 <- plot(pitch, show_voicing = FALSE)
  expect_s3_class(p2, "ggplot")
})

test_that(
  "plot.Pitch show_voicing actually colors by strength (was a dead column name)", {
  pitch <- fixture_sound()$to_pitch()
  # show_voicing = TRUE must pull the strength column (Pitch$as_data_frame()
  # names it "strength", not "voicing_strength") and color by it.
  p <- plot(pitch, show_voicing = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true("strength" %in% names(p$data))
  # show_voicing = FALSE omits the strength column.
  p2 <- plot(pitch, show_voicing = FALSE)
  expect_false("strength" %in% names(p2$data))
})

test_that("plot.Formant renders long-format time/formant/frequency columns", {
  formant <- fixture_sound()$to_formant_burg()
  p <- plot(formant, max_formant = 3)
  expect_s3_class(p, "ggplot")
  expect_true(
    all(c("time", "formant", "frequency", "bandwidth") %in% names(p$data)))
})

test_that("plot.Intensity renders a ggplot with time/intensity_db columns", {
  intensity <- fixture_sound()$to_intensity()
  p <- plot(intensity)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "intensity_db") %in% names(p$data)))
})

test_that("plot.Spectrum renders frequency/power_db and supports log_freq", {
  spectrum <- fixture_sound()$to_spectrum()
  p <- plot(spectrum)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("frequency", "power_db") %in% names(p$data)))
  p_log <- plot(spectrum, log_freq = TRUE)
  expect_s3_class(p_log, "ggplot")
})

test_that("plot.Ltas renders a ggplot with frequency/power_db columns", {
  ltas <- fixture_sound()$to_ltas(bandwidth = 100)
  p <- plot(ltas)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("frequency", "power_db") %in% names(p$data)))
})

test_that("plot.Harmonicity renders a ggplot with time/hnr_db columns", {
  hnr <- fixture_sound()$to_harmonicity_cc()
  p <- plot(hnr)
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "hnr_db") %in% names(p$data)))
})

test_that("plot.PointProcess renders a ggplot with time points", {
  pp <- fixture_sound()$to_point_process_periodic_cc()
  p <- plot(pp)
  expect_s3_class(p, "ggplot")
  expect_true("time" %in% names(p$data))
})

test_that("plot.TextGrid renders a ggplot", {
  tg <- textgrid_create(0, 1, "words")
  p <- plot(tg)
  expect_s3_class(p, "ggplot")
})

test_that("plot_powercepstrum show_peak and show_trendline branches render", {
  cepstrum <- fixture_sound()$to_spectrum()$to_power_cepstrum()
  # Peak marker (annotation) + trendline (lm fit) enabled
  p <- plot_powercepstrum(cepstrum, show_peak = TRUE, show_trendline = TRUE,
                          quefrency_range = c(0.001, 0.02))
  expect_s3_class(p, "ggplot")
  expect_true(all(c("quefrency", "power_db") %in% names(p$data)))
  # Both disabled — should still render (no peak/trendline layers)
  p2 <- plot_powercepstrum(cepstrum, show_peak = FALSE, show_trendline = FALSE)
  expect_s3_class(p2, "ggplot")
})

test_that("plot_cpp_timeseries smooth and reference_lines branches render", {
  cepstrogram <- fixture_sound()$to_powercepstrogram(pitch_floor = 60,
    time_step = 0.002)
  p <- plot_cpp_timeseries(cepstrogram, n_samples = 30,
                           smooth = TRUE, reference_lines = c(0, 20))
  expect_s3_class(p, "ggplot")
  expect_true(all(c("time", "cpp") %in% names(p$data)))
})
