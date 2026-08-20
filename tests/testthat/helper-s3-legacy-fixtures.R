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
