test_that("as.data.frame methods exist for core objects", {
  methods_expected <- c(
    "as.data.frame.Sound",
    "as.data.frame.Pitch",
    "as.data.frame.Formant",
    "as.data.frame.Intensity",
    "as.data.frame.PointProcess",
    "as.data.frame.TextGrid",
    "as.data.frame.MFCC",
    "as.data.frame.LFCC"
  )
  for (m in methods_expected) {
    expect_true(is.function(tryCatch(get(m, envir = asNamespace("pladdrr")), error = function(e) NULL)),
                info = paste0("Missing S3 method: ", m))
  }
})

test_that("print methods exist for core objects", {
  methods_expected <- c(
    "print.Sound",
    "print.Pitch",
    "print.Formant",
    "print.Intensity"
  )
  for (m in methods_expected) {
    fn <- tryCatch(get(m, envir = asNamespace("pladdrr")), error = function(e) NULL)
    expect_true(is.function(fn), info = paste0("Missing S3 method: ", m))
  }
})

test_that("plot methods exist for core objects", {
  methods_expected <- c(
    "plot.Sound",
    "plot.Pitch",
    "plot.Formant",
    "plot.Intensity",
    "plot.Spectrogram",
    "plot.Spectrum",
    "plot.Harmonicity",
    "plot.PointProcess",
    "plot.TextGrid"
  )
  for (m in methods_expected) {
    fn <- tryCatch(get(m, envir = asNamespace("pladdrr")), error = function(e) NULL)
    expect_true(is.function(fn), info = paste0("Missing S3 method: ", m))
  }
})

test_that("as.data.frame.PointProcess works", {

  sound <- Sound$create_tone(frequency = 440, duration = 0.5, sampling_rate = 16000)
  pp <- sound$to_point_process_periodic_cc()
  df <- as.data.frame(pp)
  expect_s3_class(df, "data.frame")
})

test_that("as.data.frame.TextGrid works", {

  tg <- textgrid_create(0, 1, "words")
  df <- as.data.frame(tg)
  expect_s3_class(df, "data.frame")
})

test_that("print.praat_sound prints expected fields (mono)", {
  x <- make_legacy_sound(n_channels = 1)
  expect_output(print(x), "Praat Sound Object")
  expect_output(print(x), "Duration:")
  expect_output(print(x), "mono")
  expect_output(print(x), "Amplitude:")
  ret <- withVisible(print(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("print.praat_sound reports stereo channel label", {
  x <- make_legacy_sound(n_channels = 2)
  expect_output(print(x), "stereo")
})

test_that("summary.praat_sound prints amplitude statistics", {
  x <- make_legacy_sound()
  expect_output(summary(x), "Praat Sound Object - Summary")
  expect_output(summary(x), "Mean:")
  expect_output(summary(x), "RMS:")
  expect_output(summary(x), "Std Dev:")
  ret <- withVisible(summary(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("as.data.frame.praat_sound is deprecated and returns time/amplitude columns", {
  x <- make_legacy_sound()
  # Test that warning is produced
  expect_warning(as.data.frame(x), "deprecated")
  # Get the result without warning
  df <- suppressWarnings(as.data.frame(x))
  expect_s3_class(df, "data.frame")
  expect_named(df, c("time", "amplitude"))
  expect_equal(nrow(df), x$n_samples)
})

test_that("as.data.frame.praat_sound validates its input", {
  bad <- list(not_a_sound = TRUE)
  class(bad) <- "praat_sound"
  expect_error(
    suppressWarnings(as.data.frame(bad)),
    "must be a praat_sound object"
  )
})

test_that("as.data.frame.Sound delegates to Sound$as_data_frame()", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate = 8000)
  df <- as.data.frame(sound)
  expect_s3_class(df, "data.frame")
  expect_true("time" %in% names(df))
  expect_equal(df, sound$as_data_frame())
})

test_that("print.praat_pitch reports voiced/unvoiced statistics", {
  x <- make_legacy_pitch()
  expect_output(print(x), "Praat Pitch Object")
  expect_output(print(x), "Voiced:")
  expect_output(print(x), "Pitch Statistics")
  expect_output(print(x), "Std Dev:")
  ret <- withVisible(print(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("print.praat_pitch omits pitch statistics when fully unvoiced", {
  x <- make_legacy_pitch(all_unvoiced = TRUE)
  out <- capture.output(print(x))
  expect_false(any(grepl("Pitch Statistics", out, fixed = TRUE)))
  expect_true(any(grepl("Voiced:\\s+0", out)))
})

test_that("summary.praat_pitch reports quantiles when voiced frames exist", {
  x <- make_legacy_pitch()
  expect_output(summary(x), "Praat Pitch Object - Summary")
  expect_output(summary(x), "Quantiles:")
  expect_output(summary(x), "25%:")
  expect_output(summary(x), "75%:")
  ret <- withVisible(summary(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("summary.praat_pitch reports no voiced frames when fully unvoiced", {
  x <- make_legacy_pitch(all_unvoiced = TRUE)
  expect_output(summary(x), "No voiced frames detected")
})

test_that("print.praat_formant prints header and head of values", {
  x <- make_legacy_formant()
  expect_output(print(x), "Praat Formant Object")
  expect_output(print(x), "Number of formants tracked: 2")
  expect_output(print(x), "First few measurements:")
  ret <- withVisible(print(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("summary.praat_formant reports per-formant stats across the loop", {
  x <- make_legacy_formant(n_formants = 2)
  out <- capture.output(summary(x))
  expect_true(any(grepl("Formant F1:", out, fixed = TRUE)))
  expect_true(any(grepl("Formant F2:", out, fixed = TRUE)))
  expect_true(any(grepl("Mean: .* Hz", out)))
  ret <- withVisible(summary(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("summary.praat_formant reports no valid measurements for an all-NA formant", {
  x <- make_legacy_formant(n_formants = 2, all_na_formant = 2)
  out <- capture.output(summary(x))
  f2_idx <- grep("Formant F2:", out, fixed = TRUE)
  expect_true(any(grepl("No valid measurements", out[f2_idx:(f2_idx + 2)], fixed = TRUE)))
})

test_that("as.data.frame.praat_formant returns the values data.frame", {
  x <- make_legacy_formant()
  df <- as.data.frame(x)
  expect_identical(df, x$values)
})

test_that("print.praat_intensity prints header and head of values", {
  x <- make_legacy_intensity()
  expect_output(print(x), "Praat Intensity Object")
  expect_output(print(x), "Mean subtracted: yes")
  expect_output(print(x), "First few measurements:")
  ret <- withVisible(print(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("print.praat_intensity reports 'no' when mean not subtracted", {
  x <- make_legacy_intensity()
  x$subtract_mean <- FALSE
  expect_output(print(x), "Mean subtracted: no")
})

test_that("summary.praat_intensity reports statistics when valid frames exist", {
  x <- make_legacy_intensity()
  expect_output(summary(x), "Intensity statistics:")
  expect_output(summary(x), "Mean: .* dB")
  expect_output(summary(x), "Range: .* dB")
  ret <- withVisible(summary(x))
  expect_false(ret$visible)
  expect_identical(ret$value, x)
})

test_that("summary.praat_intensity reports no valid measurements when all NA", {
  x <- make_legacy_intensity(all_na = TRUE)
  expect_output(summary(x), "No valid intensity measurements")
})

test_that("as.data.frame.praat_intensity returns the values data.frame", {
  x <- make_legacy_intensity()
  df <- as.data.frame(x)
  expect_identical(df, x$values)
})

test_that("as.data.frame.Formant delegates and forwards ... (max_formants)", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  formant <- sound$to_formant_burg()
  df_default <- as.data.frame(formant)
  expect_s3_class(df_default, "data.frame")
  expect_true(all(c("time", "formant", "frequency", "bandwidth") %in% names(df_default)))

  df_limited <- as.data.frame(formant, max_formants = 2)
  expect_s3_class(df_limited, "data.frame")
  expect_lte(max(df_limited$formant), 2)
})

test_that("as.data.frame.Intensity delegates to Intensity$as_data_frame()", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
  intensity <- sound$to_intensity()
  df <- as.data.frame(intensity)
  expect_s3_class(df, "data.frame")
  expect_equal(df, intensity$as_data_frame())
})

test_that("as.data.frame.Pitch delegates to Pitch$as_data_frame()", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  pitch <- sound$to_pitch()
  df <- as.data.frame(pitch)
  expect_s3_class(df, "data.frame")
  expect_equal(df, pitch$as_data_frame())
})

test_that("as.data.frame.MFCC delegates to MFCC$as_data_frame()", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  mfcc <- sound$to_mel_spectrogram()$to_mfcc()
  df <- as.data.frame(mfcc)
  expect_s3_class(df, "data.frame")
  expect_equal(df, mfcc$as_data_frame())
})

test_that("as.data.frame.LFCC delegates to LFCC$as_data_frame()", {
  sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
  lfcc <- sound$to_lpc_burg()$to_lfcc()
  df <- as.data.frame(lfcc)
  expect_s3_class(df, "data.frame")
  expect_equal(df, lfcc$as_data_frame())
})
