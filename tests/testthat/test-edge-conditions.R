#' @srrstats {TS1.4} A `ts` argument's start and frequency are carried into `start_time` and `sampling_rate` (`tests/testthat/test-edge-conditions.R`).
#' @srrstats {G5.8} `tests/testthat/test-edge-conditions.R`: a matrix of degenerate inputs against five core analyses.
#' @srrstats {G5.8a} Zero-length input is rejected at construction (`test-edge-conditions.R`).
#' @srrstats {G5.8b} Character and complex input are rejected (`test-edge-conditions.R`).
#' @srrstats {G5.8c} All-NA, NaN, Inf (rejected), silent, constant (DC) and clipped signals (`test-edge-conditions.R`).
#' @srrstats {G5.8d} Signals shorter than the analysis window, non-finite and out-of-range parameters (`test-edge-conditions.R`).

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
    expect_error(analyses[[an]]$fn(short), "needs at least", class = "pladdrr_input_error", info = an)
  }
  expect_s3_class(analyses$formant$fn(short), "Formant")
  expect_error(Sound$from_values(0.5, sr)$to_pitch_cc(), "needs at least", class = "pladdrr_input_error")
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

test_that("integer, ts and units vectors are accepted as sample input (G2.6)", {
  ints <- as.integer(round(1000 * tone(1600)))
  expect_equal(Sound$from_values(ints, sr)$get_number_of_samples(), 1600L)

  series <- stats::ts(tone(1600), start = 0.5, frequency = sr)
  from_ts <- Sound$from_values(series)
  expect_equal(from_ts$get_sampling_frequency(), sr)
  expect_equal(from_ts$get_start_time(), 0.5)
  # explicit arguments win over the series' own attributes
  expect_equal(Sound$from_values(series, sampling_rate = 8000)$get_sampling_frequency(), 8000)

  skip_if_not_installed("units")
  with_units <- units::set_units(tone(1600), "Pa")
  expect_equal(Sound$from_values(with_units, sr)$get_values(), tone(1600),
               tolerance = 1e-12)
})

test_that("tiers keep their points in time order however they are inserted (TS1.6)", {
  pt <- PitchTier(0, 1)
  pt$add_point(0.8, 200); pt$add_point(0.2, 100); pt$add_point(0.5, 150)
  expect_equal(as.data.frame(pt)$time, c(0.2, 0.5, 0.8))
  expect_equal(as.data.frame(pt)$frequency, c(100, 150, 200))
})

test_that("the too-short diagnostic states the required duration and matches Praat's limit (TS2.4a)", {
  # limits measured against the Praat sources: AC 3/floor, CC 2/floor, intensity 6.4/floor
  at <- function(seconds) Sound$from_values(0.5 * sin(2 * pi * 200 * (seq_len(round(seconds * sr)) - 1) / sr), sr)
  expect_error(at(0.039)$to_pitch_ac(pitch_floor = 75),
               "sound$to_pitch_ac(): the sound lasts 0.039 s but an analysis with pitch_floor = 75 Hz needs at least 0.04 s (3 periods",
               fixed = TRUE)
  expect_s3_class(at(0.040)$to_pitch_ac(pitch_floor = 75), "Pitch")
  expect_error(at(0.026)$to_pitch_cc(pitch_floor = 75), "needs at least 0.0267 s", fixed = TRUE)
  expect_s3_class(at(0.027)$to_pitch_cc(pitch_floor = 75), "Pitch")
  expect_error(at(0.08)$to_intensity(minimum_pitch = 75), "needs at least 0.0853 s", fixed = TRUE)
  expect_s3_class(at(0.09)$to_intensity(minimum_pitch = 75), "Intensity")
  expect_error(at(0.05)$to_harmonicity_cc(min_pitch = 75, periods_per_window = 3),
               "needs at least 0.0533 s", fixed = TRUE)
})
