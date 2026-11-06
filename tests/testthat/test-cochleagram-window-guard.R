## F-security-08: a sampling rate too low for the analysis window must raise,
## not abort the R process. Before the guard, nsamp_window went negative
## (floor(window_length * rate) / 2 - 1 < 0), Sound_createSimple took a negative
## duration, and the FFT zero-padding step in fon/Sound_and_Spectrum.cpp:30 wrote
## before a 1-cell allocation: "free(): invalid pointer", exit 134, uncatchable
## by tryCatch(). Praat's own Sound_to_Pitch.cpp has guarded this all along
## ("Analysis window too short."); the cochleagram path omitted it.
##
## Run as a fresh process: on the unfixed build the first test kills R with
## signal 6 rather than failing, which is the finding.

test_that("a too-short analysis window raises a catchable error", {
  sound <- sound_create_tone(duration = 1, sampling_rate = 10, frequency = 440)
  expect_error(sound$to_cochleagram(), "window too short")
})

test_that("the module door is guarded too (the R wrapper is not the only path)", {
  sound <- sound_create_tone(duration = 1, sampling_rate = 66, frequency = 440)
  module <- pladdrr:::get_module("cochleagram_module")
  expect_error(module$Sound_to_Cochleagram(sound$.xptr, 0.01, 0.1, 0.03, 0.03),
               "window too short|Failed to create Cochleagram")
})

test_that("documented rates are unaffected", {
  sound <- Sound$create_tone(frequency = 440, duration = 0.2,
                             sampling_rate = 44100)
  expect_no_error(sound$to_cochleagram())
  # the boundary Praat's own rule implies: floor(0.03 * 44100 / 1) is ample
  expect_gte(sound$to_cochleagram()$get_number_of_frames(), 1L)
})
