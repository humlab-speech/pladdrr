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
  expect_true(is.data.frame(df))
})

test_that("as.data.frame.TextGrid works", {

  tg <- textgrid_create(0, 1, "words")
  df <- as.data.frame(tg)
  expect_true(is.data.frame(df))
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
  expect_true(is.data.frame(df))
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
  expect_true(is.data.frame(df))
  expect_true("time" %in% names(df))
  expect_equal(df, sound$as_data_frame())
})
