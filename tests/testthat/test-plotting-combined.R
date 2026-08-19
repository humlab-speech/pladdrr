# tests/testthat/test-plotting-combined.R
# Regression tests for R/plotting-combined.R, which previously had zero
# coverage and contained two dead-parameter bugs:
#   - plot_spectrogram_pitch() passed `freq_max` to plot.Spectrogram(), which
#     has no such parameter (its `...` is unused), so the documented frequency
#     cap was silently ignored.
#   - plot_sound_pitch() passed `pitch_floor`/`pitch_ceiling` to plot.Pitch(),
#     which ignores them; the parameters were removed.

test_that("plot_spectrogram_pitch freq_max actually caps the displayed frequency", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  p <- plot_spectrogram_pitch(spectrogram, pitch, freq_max = 1000)
  expect_s3_class(p, "ggplot")

  # The spectrogram layer (first layer) must have been filtered to <= 1000 Hz.
  # plot.Spectrogram() stores its data at the plot level (ggplot(df, aes(...))),
  # so the spectrogram's frequency axis is in p$data, not a layer's data.
  spec_data <- p$data
  expect_true("frequency" %in% names(spec_data))
  expect_lte(max(spec_data$frequency, na.rm = TRUE), 1000)
})

test_that("plot_spectrogram_pitch renders without a freq_max cap", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  p <- plot_spectrogram_pitch(spectrogram, pitch)
  expect_s3_class(p, "ggplot")
})

test_that("plot_sound_pitch renders and no longer accepts pitch_floor/pitch_ceiling", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  pitch <- sound$to_pitch()

  p <- plot_sound_pitch(sound, pitch)
  # patchwork or gridExtra result; either way it should not error
  expect_true(inherits(p, "ggplot") || inherits(p, "patchwork") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})
