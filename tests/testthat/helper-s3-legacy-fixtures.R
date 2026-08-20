# Shared fixtures for legacy list/data.frame-based S3 classes
# (praat_sound, praat_pitch, praat_formant, praat_intensity) exercised in
# test-s3-method-coverage.R. These classes have no live R constructor in the
# package (fully migrated to R6) — fixtures mirror R/s3-methods.R's own
# roxygen @examples exactly.

make_legacy_sound <- function(n_channels = 1) {
  n_samples <- 4000
  values <- sin(2 * pi * 150 * seq(0, 0.5, length.out = n_samples))
  x <- list(
    duration = 0.5,
    sampling_rate = 8000,
    n_samples = n_samples,
    n_channels = n_channels,
    start_time = 0,
    end_time = 0.5,
    values = values,
    time = seq(0, 0.5, length.out = n_samples)
  )
  class(x) <- "praat_sound"
  x
}

make_legacy_pitch <- function(all_unvoiced = FALSE) {
  freqs <- if (all_unvoiced) {
    rep(NA_real_, 5)
  } else {
    c(120, 125, NA, 130, 128)
  }
  x <- data.frame(
    time = c(0.1, 0.2, 0.3, 0.4, 0.5),
    frequency = freqs
  )
  class(x) <- c("praat_pitch", "data.frame")
  x
}

make_legacy_formant <- function(n_formants = 2, all_na_formant = NULL) {
  times <- c(0.1, 0.2, 0.3)
  rows <- do.call(rbind, lapply(seq_len(n_formants), function(f) {
    freqs <- if (!is.null(all_na_formant) && f == all_na_formant) {
      rep(NA_real_, length(times))
    } else {
      500 * f + c(0, 5, -5)
    }
    data.frame(
      time = times,
      formant_number = f,
      frequency = freqs,
      bandwidth = 80 + f
    )
  }))
  x <- list(
    n_frames = length(times),
    n_formants = n_formants,
    time_step = 0.01,
    max_formant = 5000,
    window_length = 0.025,
    values = rows
  )
  class(x) <- "praat_formant"
  x
}

make_legacy_intensity <- function(all_na = FALSE) {
  intensities <- if (all_na) rep(NA_real_, 4) else c(62.1, 65.2, 66.1, 64.8)
  x <- list(
    n_frames = 4,
    time_step = 0.01,
    minimum_pitch = 100,
    window_length = 0.032,
    subtract_mean = TRUE,
    values = data.frame(
      time = c(0.1, 0.2, 0.3, 0.4),
      intensity_db = intensities
    )
  )
  class(x) <- "praat_intensity"
  x
}
