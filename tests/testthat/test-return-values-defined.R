# G5.3: for a clean, voiced signal the analyses below return no NA, NaN or Inf.
# (Undefined values are legitimate for unvoiced or silent input: that is covered
# in vignettes/terminology.Rmd and tests/testthat/test-edge-conditions.R.)

vowel <- klattgrid_create_from_vowel(duration = 0.5, f0start = 120)$to_sound()

all_defined <- function(x) all(is.finite(unlist(lapply(as.list(x), function(col) if (is.numeric(col)) col))))

test_that("sample and spectral objects of a voiced vowel are fully defined", {
  expect_true(all(is.finite(vowel$get_values())))
  expect_true(all_defined(as.data.frame(vowel$to_intensity())))
  expect_true(all_defined(as.data.frame(vowel$to_spectrum())))
  expect_true(all_defined(as.data.frame(vowel$to_mfcc())))
  expect_true(all_defined(as.data.frame(vowel$to_spectrogram())))
})

test_that("pitch, formant and harmonicity summaries of a voiced vowel are finite", {
  pitch <- vowel$to_pitch_cc()
  expect_true(is.finite(pitch$get_mean(0, 0, "Hertz")))
  formant <- vowel$to_formant_burg()
  for (n in 1:3) expect_true(is.finite(formant$get_value_at_time(n, 0.25, "hertz")), info = paste("F", n))
  expect_true(is.finite(vowel$to_harmonicity_cc()$get_mean(0, 0)))
  freq <- as.data.frame(pitch)$frequency
  voiced <- freq[!is.na(freq) & freq > 0]
  expect_gt(length(voiced), 0L)
  expect_true(all(is.finite(voiced)))
})

test_that("jitter and shimmer of a voiced vowel are finite", {
  pp <- vowel$to_point_process_periodic_cc(75, 600)
  stats <- get_jitter_shimmer_batch(pp, vowel)
  expect_true(all(is.finite(unlist(stats))))
})
