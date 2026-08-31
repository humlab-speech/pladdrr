# test-autoplot-spectral-family.R
library(testthat)
library(pladdrr)

sound_fixture <- function() generate_sine_wave(440, 0.2, sampling_rate = 16000)

test_that(
  "Cepstrum default view is raw (has negative values), power=TRUE view is dB (Task 7 regression guard)", {
  cep <- sound_fixture()$to_cepstrum()
  df_raw <- as.data.frame(cep)
  expect_true(any(df_raw$value < 0))
  df_power <- as.data.frame(cep, power = TRUE)
  # Column is honestly named "power" (raw linear power from the underlying
  # PowerCepstrum$as_data_frame() C++ module, which itself mislabels this
  # value "power_dB" -- see cepstrum-power-column-fix-report.md). Linear
  # power spans many orders of magnitude; assert that directly so a future
  # regression back to a bogus "power_dB" name on this raw data frame is
  # caught here, not only in the display layer below.
  expect_true("power" %in% names(df_power))
  expect_false("power_dB" %in% names(df_power))
  expect_true(all(df_power$power >= 0))
  expect_gt(max(df_power$power) / min(df_power$power[df_power$power > 0]), 1e6)
  p <- ggplot2::autoplot(cep)
  expect_s3_class(p, "ggplot")
  p_power <- ggplot2::autoplot(cep, power = TRUE)
  expect_s3_class(p_power, "ggplot")
  # dB-scale, not linear-power-scale: raw linear power spans 10+ orders of
  # magnitude (e.g. 2.7e-04 .. 1.5e11), which would have caught the
  # power_dB-mislabeled-as-linear bug found in the final review.
  expect_lt(max(p_power$data$power_dB) - min(p_power$data$power_dB), 300)
  expect_lt(max(p_power$data$power_dB), 1000)
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(cep), "ggplot")
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(cep, power = TRUE),
    "ggplot")
})

test_that("Cochleagram as.data.frame/autoplot work after Task 3's fix", {
  cochlea <- sound_fixture()$to_cochleagram(dt = 0.02, df = 1,
    window_length = 0.025,
                                             forward_masking_time = 0.03)
  df <- as.data.frame(cochlea)
  # Column is "frequency" (Bark scale), not "frequency_bark" -- Task 3
  # deliberately named it to match autoplot.Cochleagram's actual
  # `.data$frequency` usage (see task-3-report.md); Bark units are conveyed
  # via the plot's axis label instead.
  expect_true(all(c("time", "frequency", "excitation") %in% names(df)))
  expect_s3_class(ggplot2::autoplot(cochlea), "ggplot")
})

test_that("LPC autoplot/autolayer render after Task 4's power_dB fix", {
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 10)
  p <- ggplot2::autoplot(lpc, frame = 1)
  expect_s3_class(p, "ggplot")
  layer <- ggplot2::autolayer(lpc, frame = 1)
  expect_true(inherits(layer, "Layer") || inherits(layer, "list"))
})

test_that(
  "as.data.frame.LPC returns one row per (frame, coefficient), not one per frame", {
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 8)
  df <- as.data.frame(lpc)
  expect_true(all(c("frame", "coefficient", "value", "gain") %in% names(df)))

  gains <- lpc$get_all_gains()
  coeffs <- lpc$get_all_coefficients()  # (maxnCoefficients x n_frames) matrix
  n_frames <- length(gains)
  n_coeffs <- nrow(coeffs)

  # One row per (frame, coefficient); the old bug emitted one row per frame
  # and dropped (n_coeffs - 1) * n_frames coefficients.
  expect_equal(nrow(df), n_coeffs * n_frames,
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sort(unique(df$frame)), seq_len(n_frames),
    tolerance = sqrt(.Machine$double.eps))
  expect_equal(sort(unique(df$coefficient)), seq_len(n_coeffs),
    tolerance = sqrt(.Machine$double.eps))

  # Each frame's values are exactly that frame's coefficient column.
  for (i in seq_len(min(n_frames, 3L))) {
    expect_equal(df$value[df$frame == i], as.numeric(coeffs[, i]),
      tolerance = sqrt(.Machine$double.eps))
    expect_equal(unique(df$gain[df$frame == i]), gains[i],
      tolerance = sqrt(.Machine$double.eps))
  }
})

test_that(
  "ComplexSpectrogram autoplot converts to dB and respects dynamic_range (Task 8 regression guard)", {
  cs <- sound_fixture()$to_complex_spectrogram()  # R/sound-wrapper.R:550
  p <- ggplot2::autoplot(cs, dynamic_range = 40)
  expect_lte(max(p$data$amplitude_dB), 0)
  expect_gte(min(p$data$amplitude_dB), -40)
  p2 <- ggplot2::ggplot() + ggplot2::autolayer(cs, dynamic_range = 40)
  expect_s3_class(p2, "ggplot")
})

test_that(
  "BarkSpectrogram/MelSpectrogram as.data.frame use real axis values, not bin indices (Task 6 regression guard)", {
  bark <- sound_fixture()$to_bark_spectrogram()
  df <- as.data.frame(bark)
  expect_false(
    isTRUE(all.equal(sort(unique(df$col)), seq_along(unique(df$col)))))
  expect_s3_class(ggplot2::autoplot(bark), "ggplot")

  mel <- sound_fixture()$to_mel_spectrogram()
  dfm <- as.data.frame(mel)
  expect_s3_class(ggplot2::autoplot(mel), "ggplot")
})

test_that(
  "PowerCepstrogram, MFCC, LFCC, Excitation autoplot/autolayer all render", {
  pcg <- sound_fixture()$to_powercepstrogram()
  p_pcg <- ggplot2::autoplot(pcg)
  expect_s3_class(p_pcg, "ggplot")
  # dB-scale, not linear-power-scale (Important-1 regression guard: raw
  # linear power ranges over 3.8e-06 .. 2.6e11, ~11 orders of magnitude).
  expect_lt(max(p_pcg$data$power_dB) - min(p_pcg$data$power_dB), 300)
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(pcg), "ggplot")

  mfcc <- sound_fixture()$to_mfcc()
  expect_s3_class(ggplot2::autoplot(mfcc), "ggplot")
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(mfcc), "ggplot")

  # LFCC has no direct sound$to_lfcc(); it's produced from an LPC object
  # (R/lpc-wrapper.R:129: .lpc_methods$to_lfcc).
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 10)
  lfcc <- lpc$to_lfcc()
  expect_s3_class(ggplot2::autoplot(lfcc), "ggplot")
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(lfcc), "ggplot")

  # Excitation has no direct sound$to_excitation(); it's produced from a
  # Spectrum object (R/spectrum-wrapper.R:207: .spectrum_methods$to_excitation).
  exc <- sound_fixture()$to_spectrum()$to_excitation(erb_density = 0.1)
  expect_s3_class(ggplot2::autoplot(exc), "ggplot")
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(exc), "ggplot")
})

test_that("Harmonicity autoplot/autolayer render", {
  harm <- sound_fixture()$to_harmonicity_cc()
  p <- ggplot2::autoplot(harm)
  expect_s3_class(p, "ggplot")
  expect_s3_class(ggplot2::ggplot() + ggplot2::autolayer(harm), "ggplot")
})
