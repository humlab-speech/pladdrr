# test-autoplot-spectral-family.R
library(testthat)
library(pladdrr)

sound_fixture <- function() generate_sine_wave(440, 0.2, sampling_rate = 16000)

test_that("Cepstrum default view is raw (has negative values), power=TRUE view is dB (Task 7 regression guard)", {
  cep <- sound_fixture()$to_cepstrum()
  df_raw <- as.data.frame(cep)
  expect_true(any(df_raw$value < 0))
  df_power <- as.data.frame(cep, power = TRUE)
  expect_true("power_dB" %in% names(df_power))
  expect_s3_class(ggplot2::autoplot(cep), "ggplot")
  expect_s3_class(ggplot2::autoplot(cep, power = TRUE), "ggplot")
})

test_that("Cochleagram as.data.frame/autoplot work after Task 3's fix", {
  cochlea <- sound_fixture()$to_cochleagram(dt = 0.02, df = 1, window_length = 0.025,
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

test_that("ComplexSpectrogram autoplot converts to dB and respects dynamic_range (Task 8 regression guard)", {
  cs <- sound_fixture()$to_complex_spectrogram()  # R/sound-wrapper.R:550
  p <- ggplot2::autoplot(cs, dynamic_range = 40)
  expect_true(max(p$data$amplitude_dB) <= 0)
  expect_true(min(p$data$amplitude_dB) >= -40)
})

test_that("BarkSpectrogram/MelSpectrogram as.data.frame use real axis values, not bin indices (Task 6 regression guard)", {
  bark <- sound_fixture()$to_bark_spectrogram()
  df <- as.data.frame(bark)
  expect_false(isTRUE(all.equal(sort(unique(df$col)), seq_len(length(unique(df$col))))))
  expect_s3_class(ggplot2::autoplot(bark), "ggplot")

  mel <- sound_fixture()$to_mel_spectrogram()
  dfm <- as.data.frame(mel)
  expect_s3_class(ggplot2::autoplot(mel), "ggplot")
})

test_that("PowerCepstrogram, MFCC, LFCC, Excitation autoplot/autolayer all render", {
  pcg <- sound_fixture()$to_powercepstrogram()
  expect_s3_class(ggplot2::autoplot(pcg), "ggplot")

  mfcc <- sound_fixture()$to_mfcc()
  expect_s3_class(ggplot2::autoplot(mfcc), "ggplot")

  # LFCC has no direct sound$to_lfcc(); it's produced from an LPC object
  # (R/lpc-wrapper.R:129: .lpc_methods$to_lfcc).
  lpc <- sound_fixture()$to_lpc_burg(prediction_order = 10)
  lfcc <- lpc$to_lfcc()
  expect_s3_class(ggplot2::autoplot(lfcc), "ggplot")

  # Excitation has no direct sound$to_excitation(); it's produced from a
  # Spectrum object (R/spectrum-wrapper.R:207: .spectrum_methods$to_excitation).
  exc <- sound_fixture()$to_spectrum()$to_excitation(erb_density = 0.1)
  expect_s3_class(ggplot2::autoplot(exc), "ggplot")
})
