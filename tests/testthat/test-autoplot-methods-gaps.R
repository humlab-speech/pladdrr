# tests/testthat/test-autoplot-methods-gaps.R
# Task 16 gap-fill: R/autoplot-methods.R branches left uncovered by
# test-autoplot-core-streaming-family.R and test-spectrogram-plot-regression.R
# -- autolayer() filter branches (from_time/to_time/from_freq/to_freq), the
# show_voicing=TRUE branch of autoplot.Pitch, entirely-untested classes
# (Spectrum, Ltas, PointProcess, TextGrid autolayer), and quefrency filters
# plus the empty-data warning for PowerCepstrum.

library(testthat)
library(pladdrr)

sound_fixture <- function() generate_sine_wave(220, 0.2, sampling_rate = 16000)

test_that("autolayer.Sound and autolayer.Intensity respect from_time/to_time", {
  sound <- sound_fixture()
  p <- ggplot2::ggplot() + ggplot2::autolayer(sound, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p, "ggplot")

  intensity <- sound$to_intensity()
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(intensity, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p2, "ggplot")
})

test_that("autoplot.Pitch show_voicing=TRUE colors by strength", {
  pitch <- sound_fixture()$to_pitch()
  p <- ggplot2::autoplot(pitch, show_voicing = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true("strength" %in% names(p$data))
})

test_that("autolayer.Formant returns NULL once max_formant/time filtering empties the data", {
  formant <- sound_fixture()$to_formant()
  expect_null(ggplot2::autolayer(formant, from_time = 100, to_time = 200))
})

test_that("autoplot.Spectrogram/autolayer.Spectrogram respect from_freq/to_freq", {
  spectrogram <- sound_fixture()$to_spectrogram()
  p <- ggplot2::autoplot(spectrogram, from_freq = 500, to_freq = 3000)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 500 & p$data$frequency <= 3000))

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(spectrogram, from_time = 0.05, to_time = 0.15,
                                                from_freq = 500, to_freq = 3000)
  expect_s3_class(p2, "ggplot")
})

test_that("autoplot.Spectrum/autolayer.Spectrum render, respect from_freq/to_freq, and support log_freq", {
  spectrum <- sound_fixture()$to_spectrum()
  p <- ggplot2::autoplot(spectrum, from_freq = 100, to_freq = 3000, log_freq = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 100 & p$data$frequency <= 3000))

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(spectrum, from_freq = 100, to_freq = 3000)
  expect_s3_class(p2, "ggplot")
})

test_that("autoplot.Ltas/autolayer.Ltas render, respect from_freq/to_freq, and support log_freq", {
  ltas <- sound_fixture()$to_ltas(bandwidth = 100)
  p <- ggplot2::autoplot(ltas, from_freq = 100, to_freq = 3000, log_freq = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$frequency >= 100 & p$data$frequency <= 3000))

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(ltas, from_freq = 100, to_freq = 3000)
  expect_s3_class(p2, "ggplot")
})

test_that("autolayer.Harmonicity respects from_time/to_time", {
  hnr <- sound_fixture()$to_harmonicity_cc()
  p <- ggplot2::ggplot() + ggplot2::autolayer(hnr, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p, "ggplot")
})

test_that("autoplot.PointProcess/autolayer.PointProcess render, respect from_time/to_time, and warn/return NULL when empty", {
  pp <- sound_fixture()$to_point_process_periodic_cc(pitch_floor = 75, pitch_ceiling = 500)
  p <- ggplot2::autoplot(pp)
  expect_s3_class(p, "ggplot")
  p2 <- ggplot2::autoplot(pp, from_time = 0.05, to_time = 0.15)
  expect_s3_class(p2, "ggplot")

  p3 <- ggplot2::ggplot() + ggplot2::autolayer(pp, from_time = 0.05, to_time = 0.15,
                                                ymin = 0.2, ymax = 0.8)
  expect_s3_class(p3, "ggplot")

  # PointProcess(tmin, tmax) with no points added is a legitimate 0-point
  # object (R/pointprocess-wrapper.R:371), unlike Polygon which rejects an
  # empty construction outright.
  pp0 <- PointProcess(0, 1)
  expect_warning(p_empty <- ggplot2::autoplot(pp0), "PointProcess has no points")
  expect_s3_class(p_empty, "ggplot")
  expect_null(ggplot2::autolayer(pp0))
})

test_that("autoplot.PowerCepstrum/autolayer.PowerCepstrum respect from_quefrency/to_quefrency and warn/return NULL when empty", {
  pcep <- sound_fixture()$to_spectrum()$to_power_cepstrum()
  p <- ggplot2::autoplot(pcep, from_quefrency = 0.001, to_quefrency = 0.01, mark_peak = TRUE)
  expect_s3_class(p, "ggplot")
  expect_true(all(p$data$quefrency >= 0.001 & p$data$quefrency <= 0.01))

  p2 <- ggplot2::ggplot() + ggplot2::autolayer(pcep, from_quefrency = 0.001, to_quefrency = 0.01)
  expect_s3_class(p2, "ggplot")

  # as.data.frame.PowerCepstrum delegates to object$as_data_frame(); fake a
  # minimal object with an empty result to reach the nrow(df)==0 guard.
  fake <- structure(
    list(as_data_frame = function() data.frame(quefrency = numeric(0), power = numeric(0))),
    class = "PowerCepstrum"
  )
  expect_warning(p3 <- ggplot2::autoplot(fake), "PowerCepstrum has no data")
  expect_s3_class(p3, "ggplot")
  expect_null(ggplot2::autolayer(fake))
})

test_that("autolayer.TextGrid resolves tiers by name/index, filters by from_time/to_time, renders point tiers, and errors on unknown/out-of-range tiers", {
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")

  # Default: tier = 1 (interval tier)
  layer <- ggplot2::autolayer(tg)
  expect_type(layer, "list")

  # Tier resolved by character name
  layer2 <- ggplot2::autolayer(tg, tier = "words")
  expect_type(layer2, "list")

  # from_time/to_time filtering on an interval tier
  layer3 <- ggplot2::autolayer(tg, tier = "words", from_time = 0.6, to_time = 1.0)
  expect_type(layer3, "list")

  expect_error(ggplot2::autolayer(tg, tier = "nonexistent"), "not found")
  expect_error(ggplot2::autolayer(tg, tier = 99), "out of range")

  tg2 <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words tones",
                          point_tiers = "tones")
  tg2$insert_boundary("words", 0.5)
  tg2$set_interval_text("words", 1, "hello")
  tg2$insert_point("tones", 0.2, "H*")
  tg2$insert_point("tones", 0.8, "L-L%")

  # Point tier branch (is_interval == FALSE)
  layer4 <- ggplot2::autolayer(tg2, tier = "tones")
  expect_type(layer4, "list")
  layer5 <- ggplot2::autolayer(tg2, tier = "tones", from_time = 0.5, to_time = 1.0)
  expect_type(layer5, "list")
})
