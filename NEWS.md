# pladdrr 5.0.4

## Bug fixes

* `autoplot.Spectrogram()`, `autolayer.Spectrogram()`, and `plot.Spectrogram()`
  scrambled the frequency axis for any non-square spectrogram matrix (a
  `expand.grid()`/`as.vector()` row/column-major mismatch — a 220 Hz tone
  rendered with its peak at 2201 Hz), and plotted raw linear power directly
  as if already in dB, making the `dynamic_range` clipping parameter a
  silent no-op.
* `plot_powercepstrogram()` had the same two defects (time/quefrency-axis
  transposition and missing power-to-dB conversion), plus a hardcoded
  `max_time <- 5.0` placeholder in place of the cepstrogram's real duration.
* `plot_cpp_timeseries()` used the same hardcoded-duration placeholder, and
  a `tryCatch()` scoping bug (`cpp_values[i] <- NA` instead of `<<-` inside
  the error handler) meant a failed per-time-point CPP query silently
  became `0` instead of being dropped as `NA`.
* `plot_powercepstrum()` used a hardcoded `max_quefrency <- 0.05` placeholder
  instead of the cepstrum's real quefrency range, and plotted its
  `power_dB` column (misleadingly named — the values are raw linear power,
  not dB) without converting, putting the line trace and its own
  peak-prominence marker on incompatible scales.

  None of these 5 functions had any test coverage before this release; 12
  new regression tests were added (`test-spectrogram-plot-regression.R`,
  `test-cepstrum-plots-regression.R`).
* Follow-up fixes closing the remaining `power_dB`-mislabel call sites:
  `autoplot.PowerCepstrum()`/`autolayer.PowerCepstrum()` and
  `plot.PowerCepstrum()` still plotted the C++ `as_data_frame()`'s
  misleadingly-named `power_dB` column (raw linear power) directly under a
  "Power (dB)" axis, and selected their cepstral-peak marker with
  `which.max()` on linear power. Both now convert to a real dB `power_db`
  column before plotting (5 new tests in
  `test-powercepstrum-db-regression.R`).
* `plot_powercepstrogram(show_cpp_contour = TRUE)` drew its CPP-contour
  overlay as a flat line at a hardcoded `quefrency = 0.01` placeholder; it
  now overlays the real per-time-frame cepstral-peak quefrency, computed as
  the argmax of each frame's own raster row.
* `plot.Spectrogram()`'s `preemphasis` argument (default 50) was accepted
  but never referenced; removed as dead — pre-emphasis belongs in the DSP
  layer, not a plot method.
* `plot_cpp_timeseries()` no longer emits a cosmetic
  "Mean CPP: NaN dB (SD: NA)" subtitle when every sample fails; it now
  shows "No samples".
* `PowerCepstrum$as_data_frame()` (the C++ `RPowerCepstrum` module) returned
  a column misleadingly named `power_dB` that actually held raw linear power;
  renamed to the honest `power`. This is a breaking change for any caller
  that read `$as_data_frame()$power_dB` directly; the affected plotting
  functions now read `power` and convert to `power_db`.
* `as.data.frame.LPC()` indexed the coefficient *matrix* as if it were a flat
  list (`coeffs[[i]]`), so it emitted one row per frame with a single
  mislabeled coefficient and silently dropped the other
  `maxnCoefficients - 1` coefficients of every frame. It now reads each
  frame's coefficient column (`coeffs[, i]`), yielding one row per
  (frame, coefficient) as documented.
* `AmplitudeTier$to_intensity_tier()` and `AmplitudeTier$save()` called
  non-existent internal wrappers (`.amplitudetier_to_intensitytier()` /
  `.amplitudetier_save()`), so both errored with "could not find function".
  They now dispatch through the Rcpp module (`to_intensity_tier_ptr()` /
  `save()`). Six `get_shimmer_*()` AmplitudeTier methods were also removed:
  shimmer is a PointProcess metric (already present there), and these
  AmplitudeTier copies had no C++ implementation.
* `plot_spectrogram_pitch()`'s `freq_max` argument (documented "Maximum
  frequency to display") was silently ignored — it was passed to
  `plot.Spectrogram()`, which has no such parameter. It now maps to
  `plot.Spectrogram()`'s `to_freq`, so the frequency cap is honored.
* `plot_sound_pitch()`'s `pitch_floor`/`pitch_ceiling` arguments were dead —
  passed to `plot.Pitch()`, which ignores them. Removed.
* Deprecated `get_intensity_at_time()`'s `interpolate` argument and
  `create_sound()`'s `start_time` argument were silently ignored; both now
  forward to the underlying R6 methods.
* `plot.Pitch()`/`autoplot.Pitch()`'s `show_voicing` argument never colored
  by voicing strength: it looked for a `voicing_strength` column, but
  `Pitch$as_data_frame()` names it `strength` (and only includes it with
  `include_strength = TRUE`). Both now pull the strength column and color by it.
* `autolayer.PointProcess()`'s `ymin`/`ymax` arguments were ignored (it used
  `geom_vline`), `autoplot.PCA()`/`autoplot.Discriminant()`'s `garnish`
  argument was dead, and `.formant_colors()`'s `max_formant` was redundant.
  All now honor their documented behavior.

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
