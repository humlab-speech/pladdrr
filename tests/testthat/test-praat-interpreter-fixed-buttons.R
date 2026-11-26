## Issue #11: Praat's fixed-button commands (Rename..., Copy..., Info, Remove)
## were not registered in library mode, so `Rename: "x"` failed with "Command
## not available for current selection".

test_that("Rename: after To Pitch makes the object retrievable (issue #11)", {
  snd <- Sound$create_tone(0.5, 22050, 150, 0.5)
  interp <- PraatInterpreter$new()
  on.exit(interp$clear_objects(), add = TRUE)
  interp$set_object("vowel", snd)
  interp$run('
    selectObject: "Sound vowel"
    To Pitch: 0, 75, 600
    Rename: "vowel_f0"
  ')
  pitch <- interp$get_object("vowel_f0", type = "Pitch")
  expect_s3_class(pitch, "Pitch")
  expect_true(is.finite(pitch$get_mean(0, 0, "hertz")))
})

test_that("Copy: and Remove work, and Rename: errors without a selection", {
  snd <- Sound$create_tone(0.2, 22050, 150, 0.5)
  interp <- PraatInterpreter$new()
  on.exit(interp$clear_objects(), add = TRUE)
  interp$clear_objects()
  interp$set_object("a", snd)
  interp$run('
    selectObject: "Sound a"
    Copy: "b"
  ')
  expect_s3_class(interp$get_object("b", type = "Sound"), "Sound")
  interp$run('
    selectObject: "Sound b"
    Remove
  ')
  expect_error(interp$get_object("b"))
  expect_error(interp$run("Rename: \"c\""), "No object selected")
})
