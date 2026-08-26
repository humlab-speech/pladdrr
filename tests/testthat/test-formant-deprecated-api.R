# test-formant-deprecated-api.R - Tests for R/formant.R's deprecated S3-era
# API (extract_formants/get_formant_at_time/get_mean_formant). These are
# still exported and shipped (removal targeted for v5.0.0), so still worth
# covering directly -- see test-formant.R for the *previous*, now-stale
# attempt at this (skip()'d wholesale; it assumed generate_sine_wave()
# returns a legacy S3 praat_sound, which it no longer does).
#
# NOTE: exercising the legacy S3 branch of extract_formants() (the pure-R
# Burg/LPC reimplementation in .burg_algorithm()/.lpc_to_formants()) is what
# surfaced a real out-of-bounds indexing bug: f/b were reassigned to
# shrinking vectors each iteration, so the next iteration's f[(k+1):n]/
# b[k:(n-1)] slice ran past the end and pulled in R's NA-padded
# out-of-bounds values, plus a[i+1] read one past the current-order
# coefficient vector. Together these poisoned the LPC coefficients with NA
# from k=2 onward, so this path always returned NA frequencies. Both are
# fixed in R/formant.R; the legacy Burg estimator still only recovers a
# formant on a subset of frames (short-window LPC pole estimation is
# inherently noisy), so tests here assert it runs and yields *some* finite
# frequencies, not that every frame resolves one.

legacy_praat_sound <- function(values, sampling_rate = 8000) {
  n <- length(values)
  structure(
    list(
      values = values,
      time = seq(0, (n - 1) / sampling_rate, length.out = n),
      sampling_rate = sampling_rate,
      n_samples = n,
      duration = n / sampling_rate,
      start_time = 0,
      end_time = n / sampling_rate
    ),
    class = "praat_sound"
  )
}

legacy_praat_formant <- function() {
  structure(
    list(
      values = data.frame(
        time = c(0.1, 0.1, 0.2, 0.2),
        formant_number = c(1, 2, 1, 2),
        frequency = c(500, 1500, 520, 1480),
        bandwidth = c(80, 120, 85, 110)
      ),
      n_frames = 2,
      n_formants = 2
    ),
    class = "praat_formant"
  )
}

test_that("extract_formants() on an R6 Sound delegates to sound$to_formant_burg()", {
  sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)

  expect_warning(formants <- extract_formants(sound, max_formant = 5500), "deprecated")

  expect_s3_class(formants, "Formant")
  expect_true(formants$get_mean(formant_number = 1) > 0)
})

test_that("extract_formants() on a legacy praat_sound runs the R Burg-algorithm path", {
  set.seed(1)
  sr <- 16000
  signal <- sin(2 * pi * 500 * seq(0, 0.3, by = 1 / sr)) +
    0.5 * sin(2 * pi * 1500 * seq(0, 0.3, by = 1 / sr)) +
    rnorm(sr * 0.3 + 1, sd = 0.01)
  sound <- legacy_praat_sound(signal, sampling_rate = sr)

  expect_warning(
    formants <- extract_formants(sound, max_formant = 5000, n_formants = 3, window_length = 0.025),
    "deprecated"
  )

  expect_true(all(c("values", "n_frames", "time_step", "max_formant", "n_formants") %in% names(formants)))
  expect_true(all(c("time", "formant_number", "frequency", "bandwidth") %in% names(formants$values)))
  expect_equal(formants$n_formants, 3)
  expect_gt(nrow(formants$values), 0)
  # Before the array-indexing fix, this was always 0 (every frequency NA).
  expect_gt(sum(!is.na(formants$values$frequency)), 0)
})

test_that("extract_formants() validates its parameters", {
  # Non-sound input is rejected regardless of branch (R6 vs legacy S3).
  suppressWarnings(expect_error(extract_formants(42)))

  # Parameter validation (max_formant/n_formants/time_step/...) only runs
  # on the legacy S3 branch -- the R6 branch delegates straight to
  # sound$to_formant_burg(), which does not itself validate these.
  legacy <- legacy_praat_sound(sin(seq(0, 1, length.out = 800)))
  suppressWarnings({
    expect_error(extract_formants(legacy, max_formant = -100))
    expect_error(extract_formants(legacy, n_formants = 0))
    expect_error(extract_formants(legacy, n_formants = 2.5))
    expect_error(extract_formants(legacy, time_step = -0.01))
    expect_error(extract_formants(legacy, window_length = 0))
    expect_error(extract_formants(legacy, pre_emphasis_from = -10))
  })
})

test_that(".burg_algorithm() returns finite LPC coefficients for a well-behaved frame", {
  set.seed(1)
  frame <- sin(2 * pi * 500 * seq(0, 0.025, length.out = 400)) + rnorm(400, sd = 0.01)
  result <- pladdrr:::.burg_algorithm(frame, order = 8)

  expect_false(is.null(result))
  expect_length(result$coefficients, 8)
  expect_true(all(is.finite(result$coefficients)))
  expect_true(is.finite(result$error))
  expect_gt(result$error, 0)
})

test_that(".burg_algorithm() returns NULL for degenerate input", {
  expect_null(pladdrr:::.burg_algorithm(rep(0, 100), order = 8))
  expect_null(pladdrr:::.burg_algorithm(1:5, order = 8))
})

test_that("get_formant_at_time() finds the nearest frame and interpolates", {
  formant <- legacy_praat_formant()

  expect_warning(
    nearest <- get_formant_at_time(formant, formant_number = 1, time = 0.11),
    "deprecated"
  )
  expect_equal(nearest, 500)

  interpolated <- suppressWarnings(
    get_formant_at_time(formant, formant_number = 1, time = 0.15, interpolate = TRUE)
  )
  expect_equal(interpolated, 510)

  none <- suppressWarnings(get_formant_at_time(formant, formant_number = 9, time = 0.1))
  expect_true(is.na(none))
})

test_that("get_mean_formant() averages over all frames or a restricted time_range", {
  formant <- legacy_praat_formant()

  expect_warning(
    mean_f1 <- get_mean_formant(formant, formant_number = 1),
    "deprecated"
  )
  expect_equal(mean_f1, mean(c(500, 520)))

  mean_f1_range <- suppressWarnings(
    get_mean_formant(formant, formant_number = 1, time_range = c(0.05, 0.15))
  )
  expect_equal(mean_f1_range, 500)

  none <- suppressWarnings(get_mean_formant(formant, formant_number = 9))
  expect_true(is.na(none))
})
