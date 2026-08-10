# Changelog

## pladdrr 5.0.0

### Bug fixes

- [`intensity_tier_to_amplitude_tier()`](https://humlab-speech.github.io/pladdrr/reference/intensity_tier_to_amplitude_tier.md)
  and
  [`amplitude_tier_from_point_process()`](https://humlab-speech.github.io/pladdrr/reference/amplitude_tier_from_point_process.md)
  read `$.pointer` off `IntensityTier`/`PointProcess`/`Sound` objects,
  but those classes store their external pointer under `$.xptr`
  (`$.pointer` is only an alias on `AmplitudeTier`). The mismatch
  resolved to `NULL` and failed deep in the C++ layer with
  `R_ExternalPtrAddr: argument of type NILSXP is not an external pointer`.
  Fixed both call sites to use `$.xptr`.
- [`matrix_read()`](https://humlab-speech.github.io/pladdrr/reference/matrix_read.md)
  called an internal `.matrix_read()` binding that did not exist, so
  every call failed with `could not find function ".matrix_read"`
  (silently masked by an `R CMD check` NOTE-suppression entry in
  [`utils::globalVariables()`](https://rdrr.io/r/utils/globalVariables.html),
  not by a real implementation). Added the missing C++ binding
  (mirroring the existing `PitchTier`/`IntensityTier`/ `TextGrid` read
  pattern) and wired up `Matrix$save()` to the C++ save method that
  already existed but was never exposed to R.
- [`get_max_pitch()`](https://humlab-speech.github.io/pladdrr/reference/get_max_pitch.md)/[`get_min_pitch()`](https://humlab-speech.github.io/pladdrr/reference/get_min_pitch.md)
  (deprecated legacy wrappers) called
  `Pitch$get_maximum()`/`get_minimum()` with a stale `interpolation =`
  argument; the current method signature takes `interpolate =`
  (logical). Every call failed with
  `unused argument (interpolation = "none")`. Fixed to pass
  `interpolate = FALSE`.
- [`get_formant_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_formant_at_time.md)/[`get_mean_formant()`](https://humlab-speech.github.io/pladdrr/reference/get_mean_formant.md)’s
  documentation pointed users to
  [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  as the source of a compatible object, but
  [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)
  no longer produces one when given an R6 `Sound` object (it delegates
  to `sound$to_formant_burg()`, returning an R6 `Formant` object
  instead) — a stale cross-reference left over from the package’s
  S3-to-R6 migration. No behavior changed; documentation now describes
  the actual expected input and
  [`extract_formants()`](https://humlab-speech.github.io/pladdrr/reference/extract_formants.md)’s
  actual return value on both its code paths.

### Documentation

- Removed performance claims (absolute and relative) from `DESCRIPTION`
  and `README.md` per CRAN submission review, including comparisons to
  other tools such as Parselmouth. Historical changelog entries with
  benchmark data have been moved to `NEWS-archive.md`, which is not
  shipped in the package tarball.
- Reconciled the Praat module count reported in `DESCRIPTION` (37 to 38)
  to match the actual number of exposed Rcpp modules.

### Memory

- Reworked spectral moments batch calculations to compute centre of
  gravity, standard deviation, skewness, and kurtosis directly from the
  spectrogram data, removing intermediate per-frame allocations. Results
  are numerically identical to previous versions.
- Pre-allocated the output vectors used to build formant and pitch data
  frames, and made pitch data frame construction skip allocating the
  strength/intensity columns when they are not requested.
