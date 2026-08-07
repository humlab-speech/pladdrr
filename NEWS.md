# pladdrr 5.0.0

## Documentation

* Removed performance claims (absolute and relative) from `DESCRIPTION` and
  `README.md` per CRAN submission review, including comparisons to other
  tools such as Parselmouth. Historical changelog entries with benchmark
  data have been moved to `NEWS-archive.md`, which is not shipped in the
  package tarball.
* Reconciled the Praat module count reported in `DESCRIPTION` (37 to 38) to
  match the actual number of exposed Rcpp modules.

## Memory

* Reworked spectral moments batch calculations to compute centre of
  gravity, standard deviation, skewness, and kurtosis directly from the
  spectrogram data, removing intermediate per-frame allocations. Results
  are numerically identical to previous versions.
* Pre-allocated the output vectors used to build formant and pitch data
  frames, and made pitch data frame construction skip allocating the
  strength/intensity columns when they are not requested.
