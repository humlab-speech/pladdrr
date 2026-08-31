# tests/testthat/test-plotting-methods-gaps.R
# Task 16 gap-fill: R/plotting-methods.R branches left uncovered by
# test-plot-s3-behavior.R, test-spectrogram-plot-regression.R, and
# test-plotting-combined.R -- the `inherits(x, "<Class>")` type-check
# stop()s on every plot.* S3 method (called directly via `pladdrr:::`,
# since the S3 generic itself would never dispatch to the wrong method),
# from_time/to_time/from_freq/to_freq/from_quefrency/to_quefrency filters
# not otherwise exercised, plot.Matrix (entirely untested elsewhere) and
# its color_scale switch, plot.TextGrid's tier-selection branches, and the
# various empty-data warning branches.

library(testthat)
library(pladdrr)

sound_fixture <- function() Sound$create_tone(frequency = 440, duration = 0.3,
  sampling_rate = 16000)

test_that(
  "plot.* type-check stop()s fire for every S3 method with a wrong-class input", {
  expect_error(pladdrr:::plot.Sound("nope"), "x must be a Sound object")
  expect_error(pladdrr:::plot.Pitch("nope"), "x must be a Pitch object")
  expect_error(pladdrr:::plot.Formant("nope"), "x must be a Formant object")
  expect_error(pladdrr:::plot.Intensity("nope"),
    "x must be an Intensity object")
  expect_error(pladdrr:::plot.Spectrogram("nope"),
    "x must be a Spectrogram object")
  expect_error(pladdrr:::plot.Spectrum("nope"), "x must be a Spectrum object")
  expect_error(pladdrr:::plot.Ltas("nope"), "x must be an Ltas object")
  expect_error(pladdrr:::plot.Harmonicity("nope"),
    "x must be a Harmonicity object")
  expect_error(pladdrr:::plot.PointProcess("nope"),
    "x must be a PointProcess object")
  expect_error(pladdrr:::plot.Matrix("nope"), "x must be a Matrix object")
  expect_error(pladdrr:::plot.PowerCepstrum("nope"),
    "x must be a PowerCepstrum object")
  expect_error(pladdrr:::plot.TextGrid("nope"), "x must be a TextGrid object")
})

test_that(
  "plot.Formant warns and returns a placeholder plot once from_time/to_time filters everything out", {
  formant <- sound_fixture()$to_formant_burg()
  p <- plot(formant, max_formant = 3)
  expect_s3_class(p, "ggplot")

  expect_warning(p2 <- plot(formant, from_time = 100, to_time = 200),
                  "Formant object has no data to plot")
  expect_s3_class(p2, "ggplot")
})

test_that(
  "plot.Spectrogram respects from_freq (only to_freq was exercised elsewhere)", {
  spectrogram <- sound_fixture()$to_spectrogram()
  p <- plot(spectrogram, from_freq = 500, to_freq = 3000)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 500 & p$data$frequency <= 3000))
})

test_that("plot.Spectrum respects from_freq/to_freq", {
  spectrum <- sound_fixture()$to_spectrum()
  p <- plot(spectrum, from_freq = 500, to_freq = 3000)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 500 & p$data$frequency <= 3000))
})

test_that("plot.Ltas respects from_freq/to_freq and log_freq", {
  ltas <- sound_fixture()$to_ltas(bandwidth = 100)
  p <- plot(ltas, from_freq = 500, to_freq = 3000, log_freq = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 500 & p$data$frequency <= 3000))
})

test_that(
  "plot.PointProcess respects from_time/to_time and warns/returns theme_void when empty", {
  pp <- sound_fixture()$to_point_process_periodic_cc()
  p <- plot(pp, from_time = 0.05, to_time = 0.2)
  expect_s3_class(p, "ggplot")

  pp0 <- PointProcess(0, 1)
  expect_warning(p2 <- pladdrr:::plot.PointProcess(pp0),
                  "PointProcess has no points to plot")
  expect_s3_class(p2, "ggplot")
})

test_that(
  "plot.PowerCepstrum respects from_quefrency/to_quefrency and warns when empty", {
  pcep <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  p <- pladdrr:::plot.PowerCepstrum(pcep, from_quefrency = 0.001,
    to_quefrency = 0.01)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$quefrency >= 0.001 & p$data$quefrency <= 0.01))

  fake <- structure(
    list(
      as_data_frame = function() data.frame(quefrency = numeric(0),
        power = numeric(0))),
    class = "PowerCepstrum"
  )
  expect_warning(p2 <- pladdrr:::plot.PowerCepstrum(fake),
                  "PowerCepstrum contains no data")
  expect_s3_class(p2, "ggplot")
})

test_that(
  "plot.Matrix renders, respects from_x/to_x/from_y/to_y, and covers every color_scale branch", {
  mat <- Matrix(xmin = 0, xmax = 1, nx = 10, dx = 0.1, x1 = 0.05,
                ymin = 0, ymax = 2, ny = 20, dy = 0.1, y1 = 0.05)
  p <- plot(mat)
  expect_s3_class(p, "ggplot")

  p_filtered <- plot(mat, from_x = 0.2, to_x = 0.8, from_y = 0.5, to_y = 1.5)
  expect_s3_class(p_filtered, "ggplot")

  # Every named branch of the `switch(color_scale, ...)`, plus the unnamed
  # default fallback for an unrecognized value.
  for (cs in c("viridis", "magma", "plasma", "inferno", "cividis",
               "greyscale", "not_a_real_scale")) {
    p_cs <- plot(mat, color_scale = cs)
    expect_s3_class(p_cs, "ggplot")
  }

  # garnish = FALSE (labs()/theme_minimal() skipped)
  p_no_garnish <- plot(mat, garnish = FALSE)
  expect_s3_class(p_no_garnish, "ggplot")
})

test_that(
  "plot.TextGrid resolves tiers by name/index, filters by from_time/to_time, warns on unmatched tier and on a point-only tier with no interval data", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")

  # Default: all tiers (tier = NULL)
  p_default <- plot(tg)
  expect_s3_class(p_default, "ggplot")

  # tier by character name
  p_named <- plot(tg, tier = "words")
  expect_s3_class(p_named, "ggplot")

  # tier by integer index
  p_indexed <- plot(tg, tier = 1)
  expect_s3_class(p_indexed, "ggplot")

  # from_time/to_time filtering
  p_filtered <- plot(tg, from_time = 0.6, to_time = 1.0)
  expect_s3_class(p_filtered, "ggplot")

  # Unmatched tier name -> "No matching tiers found" (length(tier_indices)==0)
  expect_warning(p_nomatch <- plot(tg, tier = "nonexistent"),
                  "No matching tiers found")
  expect_s3_class(p_nomatch, "ggplot")

  # A point-only TextGrid: get_all_intervals() on the point tier errors
  # internally (caught by tryCatch -> NULL), so all_data stays empty and
  # the distinct "No interval data found" branch fires (as opposed to the
  # "no tiers at all" or "no matching tier name" branches above).
  tg2 <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "tones",
                          point_tiers = "tones")
  tg2$insert_point("tones", 0.2, "H*")
  expect_warning(p_pointonly <- plot(tg2), "No interval data found")
  expect_s3_class(p_pointonly, "ggplot")
})
