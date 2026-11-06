# Every R6 constructor that takes `.xptr` refuses a pointer to another Praat class
# (F-xptr-door, the part fix/014 left open). fix/014 guarded Matrix and PitchTier;
# `Sound(.xptr = <TextGrid>)$get_total_duration()` and nine other constructors
# still re-interpreted the foreign object and died with SIGSEGV (exit 139), and
# another 21 answered with another class's numbers. The refusal is the same
# Thing_isa test, run in each Rcpp module constructor
# (src/praat_xptr_utils.h:require_praat_class) and classed in R by
# with_pladdrr_errors().

foreign <- TextGrid(
  path = system.file("extdata/test.TextGrid", package = "pladdrr"))$.xptr

# PowerCepstrogram is deliberately absent: it is a plain function wrapper with no
# Rcpp module constructor, so there is no single place to guard it yet.
#
# Constructors whose class is not an ancestor of TextGrid, so a TextGrid pointer
# is a genuine foreign object for each. (Thing_isa is a subclass test: Matrix
# accepts a Sound, which is deliberate, and is covered by test-xptr-constructor-class.R.)
constructors <- c("Sound", "Pitch", "Formant", "FormantTier", "Intensity",
  "IntensityTier", "Excitation", "MFCC", "LFCC", "Spectrum", "Ltas", "Table",
  "PointProcess", "DurationTier", "AmplitudeTier", "LPC", "Cepstrum",
  "PowerCepstrum", "Spectrogram", "SpectrumTier",
  "Cochleagram", "Electroglottogram", "FormantGrid", "Manipulation", "Polygon",
  "DTW", "Discriminant", "PCA", "FormantModeler", "VocalTract", "Harmonicity")

test_that("each constructor refuses a TextGrid pointer with a classed error", {
  for (ctor in constructors) {
    f <- get(ctor, envir = asNamespace("pladdrr"))
    cond <- tryCatch(f(.xptr = foreign), error = function(e) e)
    expect_s3_class(cond, "pladdrr_input_error")
    expect_match(conditionMessage(cond), paste0("Not a ", ctor), info = ctor)
    expect_match(conditionMessage(cond), "found TextGrid", info = ctor)
    expect_identical(cond$param, ".xptr", info = ctor)
  }
})

test_that("TextGrid refuses a pointer to another class", {
  cond <- tryCatch(TextGrid(.xptr = matrix_create_simple(3, 4)$.xptr),
    error = function(e) e)
  expect_s3_class(cond, "pladdrr_input_error")
  expect_match(conditionMessage(cond), "Not a TextGrid")
})

test_that("a genuine pointer is still accepted, and so is a subclass", {
  snd <- Sound$create_tone(frequency = 440, duration = 0.1, sampling_rate = 8000)
  expect_s3_class(Sound(.xptr = snd$.xptr), "Sound")
  # Sound is a Matrix: Thing_isa is the subclass test, as in Praat's own readers.
  expect_s3_class(Matrix(.xptr = snd$.xptr), "Matrix")
})

test_that("the fatal constructors no longer kill the session (subprocess)", {
  # Out of process: on an unguarded build the child dies with signal 11.
  for (ctor in c("Sound", "Pitch", "TextGrid")) {
    script <- file.path(tempdir(), paste0("xptr_all_", ctor, ".R"))
    writeLines(c(
      "library(pladdrr)",
      'tg <- TextGrid(path = system.file("extdata/test.TextGrid", package = "pladdrr"))',
      "mx <- matrix_create_simple(3, 4)",
      sprintf('p <- %s', if (ctor == "TextGrid") "mx$.xptr" else "tg$.xptr"),
      sprintf('r <- tryCatch(%s(.xptr = p), pladdrr_input_error = function(e) "refused")', ctor),
      'cat("RESULT:", if (is.character(r)) r else "constructed", "\\n")'),
      script)
    out <- system2(file.path(R.home("bin"), "Rscript"), shQuote(script),
      stdout = TRUE, stderr = TRUE)
    expect_true(any(grepl("RESULT: refused", out)), info = ctor)
  }
})
