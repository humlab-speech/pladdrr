#' @srrstats {G5.9} `tests/testthat/test-noise-susceptibility.R`.
#' @srrstats {G5.9a} Machine-epsilon-scale noise leaves pitch, intensity, formants and HNR unchanged within tolerance.
#' @srrstats {G5.9b} Deterministic analyses are identical under different RNG seeds (`test-noise-susceptibility.R`); Praat's own `fit_method = "robust slow"` CPPS fit is non-deterministic upstream and documented as such (`vignettes/terminology.Rmd`, `inst/agents/FAITHFULNESS_REPORT.md`).

# G5.9a: adding noise at the scale of machine precision must not meaningfully
# change any deterministic analysis result. G5.9b: results do not depend on the
# RNG state, because none of these paths draw random numbers (Praat's
# "robust slow" trend fit is the documented exception; see FAITHFULNESS_REPORT).

vowel <- function() {
  klattgrid_create_from_vowel(duration = 0.4, f0start = 120)$to_sound()
}

test_that("machine-precision noise leaves pitch, intensity, formants and HNR unchanged", {
  withr::local_seed(20261109)
  clean <- vowel()
  values <- clean$get_values()
  eps_noise <- stats::rnorm(length(values),
                            sd = .Machine$double.eps * max(abs(values)))
  noisy <- Sound$from_values(values + eps_noise, clean$get_sampling_frequency())

  expect_equal(noisy$to_pitch_cc()$get_mean(0, 0, "Hertz"),
               clean$to_pitch_cc()$get_mean(0, 0, "Hertz"), tolerance = 1e-6)
  expect_equal(noisy$to_intensity(minimum_pitch = 100)$get_mean(0, 0, "energy"),
               clean$to_intensity(minimum_pitch = 100)$get_mean(0, 0, "energy"),
               tolerance = 1e-8)  # measured relative change 3e-9
  f_clean <- clean$to_formant_burg()
  f_noisy <- noisy$to_formant_burg()
  for (n in 1:3) {
    expect_equal(f_noisy$get_value_at_time(n, 0.2, "hertz"),
                 f_clean$get_value_at_time(n, 0.2, "hertz"), tolerance = 1e-6)
  }
  expect_equal(noisy$to_harmonicity_cc()$get_mean(0, 0),
               clean$to_harmonicity_cc()$get_mean(0, 0), tolerance = 1e-6)
})

test_that("deterministic analyses do not depend on the RNG state", {
  snd <- vowel()
  set.seed(1); a <- snd$to_pitch_cc()$get_mean(0, 0, "Hertz")
  set.seed(2); b <- snd$to_pitch_cc()$get_mean(0, 0, "Hertz")
  expect_identical(a, b)
  set.seed(1); fa <- snd$to_formant_burg()$get_value_at_time(1, 0.2, "hertz")
  set.seed(2); fb <- snd$to_formant_burg()$get_value_at_time(1, 0.2, "hertz")
  expect_identical(fa, fb)
})
