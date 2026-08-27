# tests/testthat/test-praat-interpreter-gaps.R
# Coverage gap-fill for R/praat-interpreter-wrapper.R: .wrap_praat_object()
# class mappings (only Sound/Pitch were exercised), PraatInterpreter$run(),
# and print().
#
# NOTE (2026-08-28): "To Matrix" on a Spectrogram used to segfault the R
# session. Root cause: praat_doAction() matched actions by title only, so
# the FIRST "To Matrix" action (registered for PointProcess, Cochleagram,
# Harmonicity, Ltas, Pitch, Spectrogram, ...) won regardless of the
# selected class and ran the wrong callback on the object
# (PointProcess_to_Matrix on a Spectrogram). Fixed in
# src/praat_actions_libmode.cpp: dispatch now also matches the selected
# objects' classes. "To PitchTier" (Pitch) and "To IntensityTier"
# (Manipulation) had the same crash; they now produce a clean Praat
# "command not available" error because this build registers no single-
# selection action for those conversions (the C++ converters exist; the
# action registration is upstream-slimmed).

interp_fixture <- function(tag) {
  interp <- PraatInterpreter$new()
  interp$run(sprintf('Create Sound as pure tone: "tone%s", 1, 0, 0.25, 44100, 440, 0.2, 0.01, 0.01', tag))
  interp
}

last_object <- function(interp) {
  objs <- interp$list_objects()
  interp$get_object_by_id(max(objs$id))
}

test_that("PraatInterpreter$run() executes scripts and validates input", {
  interp <- interp_fixture("run")
  expect_invisible(interp$run('Create TextGrid: 0, 1, "words", ""'))
  expect_equal(interp$eval("2 + 2"), 4)
  expect_error(interp$run(123), "single non-empty character")
  expect_error(interp$run(character()), "single non-empty character")
})

test_that("wrap_praat_object maps the core analysis classes", {
  interp <- interp_fixture("core")
  interp$run("To Pitch: 0, 75, 600")
  expect_s3_class(last_object(interp), "Pitch")
  interp$run('selectObject: "Sound tonecore"')
  interp$run("To Formant (burg): 0, 5, 5500, 0.025, 50")
  expect_s3_class(last_object(interp), "Formant")
  interp$run('selectObject: "Sound tonecore"')
  interp$run("To Intensity: 100, 0, \"yes\"")
  expect_s3_class(last_object(interp), "Intensity")
  interp$run('selectObject: "Sound tonecore"')
  interp$run("To PointProcess (periodic, cc): 75, 600")
  expect_s3_class(last_object(interp), "PointProcess")
  interp$run('selectObject: "Sound tonecore"')
  interp$run("To Harmonicity (cc): 0.01, 75, 0.1, 1")
  expect_s3_class(last_object(interp), "Harmonicity")
  interp$run('selectObject: "Sound tonecore"')
  interp$run("To Ltas: 100")
  expect_s3_class(last_object(interp), "Ltas")
})

test_that("wrap_praat_object maps spectral classes", {
  interp <- interp_fixture("spec")
  interp$run("To Spectrogram: 0.005, 5000, 0.002, 20, \"Gaussian\"")
  expect_s3_class(last_object(interp), "Spectrogram")
  interp$run('selectObject: "Sound tonespec"')
  interp$run("To Spectrum: \"yes\"")
  expect_s3_class(last_object(interp), "Spectrum")
})

test_that("wrap_praat_object maps Manipulation and TextGrid", {
  interp <- interp_fixture("misc")
  interp$run("To Manipulation: 0.01, 75, 600")
  expect_s3_class(last_object(interp), "Manipulation")
  interp$run('Create TextGrid: 0, 1, "word", ""')
  expect_s3_class(last_object(interp), "TextGrid")
})

test_that("To Matrix on a Spectrogram dispatches to the right class (regression: segfault)", {
  interp <- interp_fixture("matrix")
  interp$run("To Spectrogram: 0.005, 5000, 0.002, 20, \"Gaussian\"")
  interp$run("To Matrix")
  expect_s3_class(last_object(interp), "Matrix")
})

test_that("mis-classed conversions fail cleanly instead of crashing (regression: segfault)", {
  interp <- interp_fixture("nocrashtier")
  interp$run("To Pitch: 0, 75, 600")
  expect_error(interp$run("To PitchTier"), "not available")
  interp$run('selectObject: "Sound tonenocrashtier"')
  interp$run("To Manipulation: 0.01, 75, 600")
  expect_error(interp$run("To IntensityTier"), "not available")
})

test_that("PraatInterpreter$print() summarizes the object list", {
  interp <- interp_fixture("print")
  expect_output(interp$print(), "<PraatInterpreter>")
  expect_output(interp$print(), "Objects:")
  expect_invisible(interp$print())
})
