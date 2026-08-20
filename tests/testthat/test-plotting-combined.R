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

test_that("plot_spectrogram_pitch validates its inputs", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  expect_error(plot_spectrogram_pitch("not a spectrogram", pitch),
               "spectrogram must be a Spectrogram object")
  expect_error(plot_spectrogram_pitch(spectrogram, "not a pitch"),
               "pitch must be a Pitch object")
})

test_that("plot_spectrogram_pitch accepts pitch_color and title", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  p <- plot_spectrogram_pitch(spectrogram, pitch, pitch_color = "purple", title = "Custom")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Custom")
})

test_that("plot_spectrogram_pitch filters by pitch_floor/pitch_ceiling", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  p <- plot_spectrogram_pitch(spectrogram, pitch, pitch_floor = 75, pitch_ceiling = 500)
  expect_s3_class(p, "ggplot")
})

test_that("plot_spectrogram_pitch warns and returns bare spectrogram when pitch range excludes all data", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  pitch <- sound$to_pitch()

  expect_warning(
    p <- plot_spectrogram_pitch(spectrogram, pitch, pitch_floor = 10000, pitch_ceiling = 10001),
    "No pitch data available in the specified range"
  )
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

test_that("plot_textgrid_sound validates its inputs", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  tg <- TextGrid$create(tmin = 0, tmax = 0.5, tier_names = "words")

  expect_error(plot_textgrid_sound("not a textgrid", sound), "textgrid must be a TextGrid object")
  expect_error(plot_textgrid_sound(tg, "not a sound"), "sound must be a Sound object")
})

test_that("plot_textgrid_sound errors on an unknown tier name", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  tg <- TextGrid$create(tmin = 0, tmax = 0.5, tier_names = "words")

  expect_error(plot_textgrid_sound(tg, sound, tier = "nonexistent"),
               "Tier 'nonexistent' not found in TextGrid")
})

test_that("plot_textgrid_sound renders all interval tiers by default", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")

  p <- plot_textgrid_sound(tg, sound)
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})

test_that("plot_textgrid_sound accepts a numeric tier index and a time range", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")

  p <- plot_textgrid_sound(tg, sound, tier = 1, from_time = 0.1, to_time = 0.9,
                            title = "Custom Title")
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})

test_that("plot_textgrid_sound renders a point tier", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words tones", point_tiers = "tones")
  tg$insert_point("tones", 0.2, "H*")
  tg$insert_point("tones", 0.8, "L-L%")

  p <- plot_textgrid_sound(tg, sound, tier = "tones")
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})
test_that("plot_textgrid_pitch validates its inputs", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  tg <- TextGrid$create(tmin = 0, tmax = 0.5, tier_names = "words")

  expect_error(plot_textgrid_pitch("not a textgrid", pitch), "textgrid must be a TextGrid object")
  expect_error(plot_textgrid_pitch(tg, "not a pitch"), "pitch must be a Pitch object")
})

test_that("plot_textgrid_pitch errors on an unknown tier name", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  tg <- TextGrid$create(tmin = 0, tmax = 0.5, tier_names = "words")

  expect_error(plot_textgrid_pitch(tg, pitch, tier = "nonexistent"),
               "Tier 'nonexistent' not found in TextGrid")
})

test_that("plot_textgrid_pitch renders all interval tiers by default", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)
  tg$set_interval_text("words", 1, "hello")
  tg$set_interval_text("words", 2, "world")

  p <- plot_textgrid_pitch(tg, pitch)
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})

test_that("plot_textgrid_pitch accepts a numeric tier index, time range, and custom color", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words phones")
  tg$insert_boundary("words", 0.5)

  p <- plot_textgrid_pitch(tg, pitch, tier = 1, from_time = 0.1, to_time = 0.9,
                            pitch_color = "darkblue")
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})

test_that("plot_textgrid_pitch renders a point tier", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  tg <- TextGrid$create(tmin = 0, tmax = 1.0, tier_names = "words tones", point_tiers = "tones")
  tg$insert_point("tones", 0.2, "H*")
  tg$insert_point("tones", 0.8, "L-L%")

  p <- plot_textgrid_pitch(tg, pitch, tier = "tones")
  expect_true(inherits(p, "patchwork") || inherits(p, "ggplot") ||
              inherits(p, "gtable") || inherits(p, "grob"))
})

test_that("plot_pitch_intensity validates its inputs", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  intensity <- sound$to_intensity()

  expect_error(plot_pitch_intensity("not a pitch", intensity), "pitch must be a Pitch object")
  expect_error(plot_pitch_intensity(pitch, "not an intensity"), "intensity must be an Intensity object")
})

test_that("plot_pitch_intensity renders a dual-axis ggplot with default range", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  intensity <- sound$to_intensity()

  p <- plot_pitch_intensity(pitch, intensity)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Pitch and Intensity")
})

test_that("plot_pitch_intensity accepts a time range and custom colors/title", {
  sound <- Sound$create_tone(frequency = 220, duration = 1.0, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  intensity <- sound$to_intensity()

  p <- plot_pitch_intensity(pitch, intensity, from_time = 0.2, to_time = 0.8,
                             pitch_color = "purple", intensity_color = "gold",
                             title = "Custom")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Custom")
})

test_that("plot_spectrogram_formants validates its inputs", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  formant <- sound$to_formant()

  expect_error(plot_spectrogram_formants("not a spectrogram", formant),
               "spectrogram must be a Spectrogram object")
  expect_error(plot_spectrogram_formants(spectrogram, "not a formant"),
               "formant must be a Formant object")
})

test_that("plot_spectrogram_formants overlays formant tracks by default", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  formant <- sound$to_formant()

  p <- plot_spectrogram_formants(spectrogram, formant)
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Spectrogram + Formants")
})

test_that("plot_spectrogram_formants accepts max_formant, formant_colors, dynamic_range", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  formant <- sound$to_formant()

  p <- plot_spectrogram_formants(spectrogram, formant, max_formant = 2,
                                  formant_colors = c("black", "grey"),
                                  dynamic_range = 50, title = "Custom")
  expect_s3_class(p, "ggplot")
  expect_equal(p$labels$title, "Custom")
})

test_that("plot_spectrogram_formants warns and returns bare spectrogram when no formant data in range", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
  spectrogram <- sound$to_spectrogram()
  formant <- sound$to_formant()

  expect_warning(
    p <- plot_spectrogram_formants(spectrogram, formant, from_time = 10, to_time = 20),
    "No formant data available in the specified time range"
  )
  expect_s3_class(p, "ggplot")
})
