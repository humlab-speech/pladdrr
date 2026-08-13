# pladdrr 5.0.1

## New features

* Added `autoplot()` and `autolayer()` S3 methods for 27 previously unsupported Praat object classes: AmplitudeTier, DurationTier, IntensityTier, PitchTier, FormantTier, FormantGrid, FormantPath, Excitation, ComplexSpectrogram, Cepstrum, Cochleagram, PowerCepstrogram, MFCC, LFCC, BarkSpectrogram, MelSpectrogram, Matrix, PCA, Discriminant, FormantModeler, Electroglottogram, LongSound, DTW, Polygon, VocalTract, LPC, KlattGrid.
* Added `as.data.frame()` S3 methods for 15 classes that lacked them.

## Bug fixes

* `process_sounds_parallel()` shipped already-loaded `Sound` objects directly
  to Windows PSOCK workers; their external pointer to the underlying C++
  object cannot survive that process boundary, causing spurious errors on
  Windows with `n_cores > 1`. Sounds are now serialized to raw sample data
  and reconstructed inside each worker.
* Fixed `FormantGrid$as_data_frame()` missing required `time_step` argument.
* `autoplot.KlattGrid()`/`as.data.frame.KlattGrid()` passed a formant-type
  name as a string where the underlying accessor required an integer code,
  producing empty plots or silently wrong data for every formant type.
  Fixed to map the name to its integer code before dispatch; also corrected
  the shared `formant_type` documentation, which claimed `"all"` was an
  accepted value for `autolayer.KlattGrid()` when only `autoplot.KlattGrid()`
  actually supports it.
* `as.data.frame.Cochleagram()` always errored.
* `as.data.frame.LPC()` always errored, due to a typo'd `power_dB` column
  name that did not exist on the object.
* `autolayer.DTW()` plotted the wrong columns and crashed on some
  `NULL`-valued paths.
* `autoplot`/`autolayer`/`as.data.frame` for `Matrix`, `BarkSpectrogram`, and
  `MelSpectrogram` plotted raw row/column bin indices instead of the real
  time/frequency axis values.
* `autoplot.Cepstrum()` defaulted to a power-cepstrum dB view; Praat's actual
  default is a raw signed quefrency-domain view. Fixed the default and added
  a `power` parameter to select the dB view explicitly.
* `autoplot.ComplexSpectrogram()` and `autolayer.ComplexSpectrogram()` both
  mislabeled linear amplitude values as dB and ignored `dynamic_range`.
* `as.data.frame.VocalTract()`, `autoplot.VocalTract()`, and
  `autolayer.VocalTract()` all hardcoded section spacing (`dx`) instead of
  reading it from the object, giving wrong x-axis values whenever spacing
  was non-default.
* `autoplot.FormantTier()`/`autolayer.FormantTier()` defaulted to an
  interpolated line view; Praat's actual default view is speckle (points).
* `autoplot.FormantPath()` and `autoplot.FormantModeler()` always produced
  empty plots — the former from a column-name mismatch, the latter from a
  wide/long data-frame format mismatch.
* `as.data.frame.PowerCepstrogram()` called a nonexistent `$as_data_frame()`
  method and always crashed; fixed to route through `$to_matrix()`.
* `Sound$extract_electroglottogram()` was never registered in the R6 method
  table, despite its underlying C++ export existing and being registered;
  every call crashed with "attempt to apply non-function".

# pladdrr 5.0.0

## Bug fixes

* `intensity_tier_to_amplitude_tier()` and `amplitude_tier_from_point_process()`
  read `$.pointer` off `IntensityTier`/`PointProcess`/`Sound` objects, but
  those classes store their external pointer under `$.xptr` (`$.pointer` is
  only an alias on `AmplitudeTier`). The mismatch resolved to `NULL` and
  failed deep in the C++ layer with `R_ExternalPtrAddr: argument of type
  NILSXP is not an external pointer`. Fixed both call sites to use `$.xptr`.
* `matrix_read()` called an internal `.matrix_read()` binding that did not
  exist, so every call failed with `could not find function ".matrix_read"`
  (silently masked by an `R CMD check` NOTE-suppression entry in
  `utils::globalVariables()`, not by a real implementation). Added the
  missing C++ binding (mirroring the existing `PitchTier`/`IntensityTier`/
  `TextGrid` read pattern) and wired up `Matrix$save()` to the C++ save
  method that already existed but was never exposed to R.
* `get_max_pitch()`/`get_min_pitch()` (deprecated legacy wrappers) called
  `Pitch$get_maximum()`/`get_minimum()` with a stale `interpolation =`
  argument; the current method signature takes `interpolate =` (logical).
  Every call failed with `unused argument (interpolation = "none")`. Fixed
  to pass `interpolate = FALSE`.
* `get_formant_at_time()`/`get_mean_formant()`'s documentation pointed
  users to `extract_formants()` as the source of a compatible object, but
  `extract_formants()` no longer produces one when given an R6 `Sound`
  object (it delegates to `sound$to_formant_burg()`, returning an R6
  `Formant` object instead) — a stale cross-reference left over from the
  package's S3-to-R6 migration. No behavior changed; documentation now
  describes the actual expected input and `extract_formants()`'s actual
  return value on both its code paths.

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
