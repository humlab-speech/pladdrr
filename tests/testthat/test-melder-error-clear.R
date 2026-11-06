test_that("a failed cochleagram does not poison later Praat errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  # df = 1e-9 makes Spectrum_to_Excitation ask for an impossible tensor and
  # throws from inside Praat.
  expect_error(sound$to_cochleagram(df = 1e-9),
               "Praat error in Sound_to_Cochleagram")

  msg <- tryCatch(praat_run_script("print"), error = function(e) e$message)
  expect_false(grepl("Cochleagram", msg, fixed = TRUE))
  expect_false(grepl("not enough room", msg, fixed = TRUE))
})

test_that("a failed excitation does not poison later Praat errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  spectrum <- sound$to_spectrum()
  expect_error(spectrum$to_excitation(erb_density = 1e-9),
               "Praat error in Spectrum_to_Excitation")

  msg <- tryCatch(praat_run_script("print"), error = function(e) e$message)
  expect_false(grepl("Excitation", msg, fixed = TRUE))
  expect_false(grepl("not enough room", msg, fixed = TRUE))
})

test_that("a clean session still reports its own error only", {
  msg <- tryCatch(praat_run_script("print"), error = function(e) e$message)
  expect_match(msg, "Unknown variable")
})
