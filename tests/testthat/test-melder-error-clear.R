## F-memsec-02: a failed Praat conversion must not leave its error text armed
## in Praat's global error buffer, where it is prepended to every LATER Praat
## error in the same R session.  Each test fails a different conversion and then
## asks for an unrelated Praat error, whose message must contain only its own
## reason.  `expect_match(..., "^Unknown variable")` anchors the front so a test
## cannot pass merely because the later call stopped erroring.

.next_praat_error <- function() {
  tryCatch({
    praat_run_script("print")
    ""
  }, error = function(e) conditionMessage(e))
}

test_that("a failed cochleagram does not poison later Praat errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  expect_error(sound$to_cochleagram(df = 1e-9),
               "Praat error in Sound_to_Cochleagram")
  expect_match(.next_praat_error(), "^Unknown variable")
})

test_that("a failed edb cochleagram does not poison later Praat errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  expect_error(sound$to_cochleagram_edb(dfreq = 1e-9),
               "Praat error in Sound_to_Cochleagram_edb")
  expect_match(.next_praat_error(), "^Unknown variable")
})

test_that("a failed cochleagram-to-excitation does not poison later errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  cochleagram <- sound$to_cochleagram()
  expect_error(cochleagram$to_excitation(NA_real_),
               "Praat error in Cochleagram_to_Excitation")
  expect_match(.next_praat_error(), "^Unknown variable")
})

test_that("a failed excitation does not poison later Praat errors", {
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  spectrum <- sound$to_spectrum()
  expect_error(spectrum$to_excitation(erb_density = 1e-9),
               "Praat error in Spectrum_to_Excitation")
  expect_match(.next_praat_error(), "^Unknown variable")
})

test_that("a swallowed segment failure does not poison later Praat errors", {
  ## sound_extract_parts_pooled() is exported and its catch (...) used to
  ## discard the condition without emptying the buffer.
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  parts <- sound_extract_parts_pooled(sound$.xptr, c(0.1, NaN), c(0.2, NaN))
  expect_null(parts[[2]])
  expect_match(.next_praat_error(), "^Unknown variable")
})

test_that("the failing call itself still names the Praat reason", {
  ## Clearing the buffer must not cost the user the diagnosis: the reason has
  ## to travel in the error it belongs to (the package's own pattern, cf.
  ## src/sound_wrappers.cpp:662 and src/praat_error_handling.h).
  sound <- Sound$create_tone(frequency = 440, duration = 1.0,
                             sampling_rate = 44100)
  msg <- tryCatch(sound$to_cochleagram(df = 1e-9),
                  error = function(e) conditionMessage(e))
  expect_match(msg, "Cochleagram")
  expect_match(msg, "not converted|not created|not enough room")
})

test_that("an error raised at the end of a session that saw failures is still clean", {
  ## Deliberately last: the session has already seen four failed conversions,
  ## so this catches a leak that survives to the end rather than a fresh
  ## session (which would be trivially clean).
  expect_match(.next_praat_error(), "^Unknown variable")
})

## Site 5 of five (src/excitation_wrappers.cpp, Excitation_to_Formant) has no
## reachable trigger: max_formants of -1, 0, 1e9 and NA_integer_ all succeed on
## an Excitation from a 440 Hz tone, so its `catch` body cannot be entered from
## R. It is cleared for consistency with the other four, and is NOT covered by a
## test here (see audit/2026-11/fixes/F-memsec-02.md).
