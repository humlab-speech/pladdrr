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
