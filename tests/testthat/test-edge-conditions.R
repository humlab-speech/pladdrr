# G5.8: edge-condition matrix. Every core analysis is run on degenerate input
# and must either return an object of the right class or fail with an
# informative R error. It must never crash the session or return silently
# wrong-typed output.
#
# Contract (documented here because Praat itself defines it):
#  * zero-length, non-numeric (character, complex) and non-finite input are
#    rejected at construction
#  * silence, constant (DC) and clipped signals are valid input; analyses
#    return their object, with undefined (NaN) values where Praat has none
#  * signals shorter than the analysis window are rejected by Praat
#    ("Failed to ...") for pitch, intensity and harmonicity; Burg formant
#    analysis tolerates them
#  * a pitch ceiling above Nyquist is accepted (Praat clips it)

sr <- 16000
tone <- function(n) sin(2 * pi * 200 * (seq_len(n) - 1L) / sr)

analyses <- list(
  pitch_cc  = list(fn = function(s) s$to_pitch_cc(),         cls = "Pitch"),
  pitch_ac  = list(fn = function(s) s$to_pitch_ac(),         cls = "Pitch"),
  intensity = list(fn = function(s) s$to_intensity(),        cls = "Intensity"),
  formant   = list(fn = function(s) s$to_formant_burg(),     cls = "Formant"),
  hnr       = list(fn = function(s) s$to_harmonicity_cc(),   cls = "Harmonicity")
)

test_that("zero-length, character and non-finite input are rejected at construction (G5.8a, G5.8b)", {
  expect_error(Sound$from_values(numeric(0), sr), "empty")
  expect_error(Sound$from_values(rep("a", 100), sr), "numeric")
  expect_error(Sound$from_values(complex(real = rep(1, 10), imaginary = 1), sr),
               "values must be numeric", class = "pladdrr_input_error")
  for (bad in list(NA_real_, NaN, Inf, -Inf)) {
    v <- tone(1600); v[10] <- bad
    expect_error(Sound$from_values(v, sr), class = "pladdrr_input_error")
  }
  expect_error(Sound$from_values(rep(NA_real_, 1600), sr),
               "found 1600 NA, NaN or Inf", class = "pladdrr_input_error")
})

test_that("silence, constant and clipped signals are analysed without error (G5.8c)", {
  signals <- list(
    silence = numeric(1600),
    dc      = rep(0.5, 1600),
    clipped = pmax(pmin(3 * tone(1600), 1), -1)
  )
  for (sn in names(signals)) {
    snd <- Sound$from_values(signals[[sn]], sr)
    for (an in names(analyses)) {
      res <- analyses[[an]]$fn(snd)
      expect_s3_class(res, analyses[[an]]$cls)
    }
  }
})

test_that("signals shorter than the analysis window fail informatively or are tolerated (G5.8d)", {
  short <- Sound$from_values(tone(64), sr)
  for (an in c("pitch_cc", "pitch_ac", "intensity", "hnr")) {
    expect_error(analyses[[an]]$fn(short), "Failed to", info = an)
  }
  expect_s3_class(analyses$formant$fn(short), "Formant")
  expect_error(Sound$from_values(0.5, sr)$to_pitch_cc(), "Failed to")
})

test_that("invalid analysis parameters raise typed input errors (G5.8b, G2.0)", {
  snd <- Sound$from_values(tone(8000), sr)
  expect_error(snd$to_pitch_cc(pitch_floor = "a"), class = "pladdrr_input_error")
  expect_error(snd$to_pitch_cc(pitch_floor = -5), class = "pladdrr_input_error")
  expect_error(snd$to_pitch_cc(pitch_floor = c(75, 80)), class = "pladdrr_input_error")
  expect_error(snd$to_pitch_cc(pitch_floor = 500, pitch_ceiling = 100),
               class = "pladdrr_input_error")
  expect_error(snd$to_intensity(time_step = -1), "Failed to")
})

test_that("a pitch ceiling above Nyquist is accepted (documented Praat behaviour)", {
  snd <- Sound$from_values(tone(8000), sr)
  expect_s3_class(snd$to_pitch_cc(pitch_floor = 75, pitch_ceiling = 20000), "Pitch")
})
