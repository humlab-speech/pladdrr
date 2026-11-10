# TS5.1-TS5.3: time-domain plots put time on the horizontal axis, labelled
# "Time (s)"; frequency axes carry hertz.

axis_label <- function(p, axis) {
  labs <- if (exists("get_labs", asNamespace("ggplot2"))) ggplot2::get_labs(p) else p$labels
  as.character(labs[[axis]])
}

test_that("time-domain autoplot methods label the horizontal axis 'Time (s)'", {
  skip_if_not_installed("ggplot2")
  snd <- generate_sine_wave(200, 0.4, sampling_rate = 16000, amplitude = 0.5)
  objs <- list(
    Sound = snd,
    Pitch = snd$to_pitch_cc(),
    Formant = snd$to_formant_burg(),
    Intensity = snd$to_intensity(),
    Spectrogram = snd$to_spectrogram(),
    Harmonicity = snd$to_harmonicity_cc(),
    PointProcess = snd$to_point_process_periodic_cc(75, 600)
  )
  for (nm in names(objs)) {
    p <- suppressWarnings(ggplot2::autoplot(objs[[nm]]))
    expect_s3_class(p, "ggplot")
    expect_identical(axis_label(p, "x"), "Time (s)", info = nm)
  }
})

test_that("frequency axes are labelled in hertz", {
  skip_if_not_installed("ggplot2")
  snd <- generate_sine_wave(200, 0.4, sampling_rate = 16000, amplitude = 0.5)
  for (obj in list(snd$to_pitch_cc(), snd$to_formant_burg(), snd$to_spectrogram())) {
    expect_identical(axis_label(ggplot2::autoplot(obj), "y"), "Frequency (Hz)")
  }
})

test_that("autoplot.Pitch can break the line across unvoiced frames (TS5.5)", {
  skip_if_not_installed("ggplot2")
  sr <- 16000
  tone <- sin(2 * pi * 200 * (seq_len(0.3 * sr) - 1) / sr) * 0.5
  snd <- Sound$from_values(c(tone, numeric(0.3 * sr), tone), sr)
  pitch <- snd$to_pitch_cc()
  joined <- ggplot2::autoplot(pitch)
  broken <- ggplot2::autoplot(pitch, connect_gaps = FALSE)
  expect_false(anyNA(joined$data$frequency))
  expect_true(anyNA(broken$data$frequency))
  expect_gt(nrow(broken$data), nrow(joined$data))
})
