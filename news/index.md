# Changelog

## pladdrr 5.0.4

### Bug fixes

- The Praat interpreter entry points
  ([`praat_run_script()`](https://humlab-speech.github.io/pladdrr/reference/praat_run_script.md),
  [`praat_eval_numeric()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_numeric.md),
  [`praat_eval_string()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string.md),
  [`praat_eval_vector()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_vector.md),
  [`praat_eval_matrix()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_matrix.md),
  [`praat_eval_string_array()`](https://humlab-speech.github.io/pladdrr/reference/praat_eval_string_array.md),
  and `PraatInterpreter$run()`/`$eval()`/`$set_variable()`) now reject
  `NULL`, empty, non-scalar, or non-character inputs with a clear R
  error instead of an opaque C++ failure.

- `Sound$to_textgrid_silences()` accepted `min_silent_duration` /
  `min_sounding_duration` but silently ignored them (a `TODO`). It now
  merges short silent and sounding intervals via the same
  `IntervalTier_cutIntervals_minimumDuration` +
  `IntervalTier_combineIntervalsOnLabelMatch` passes the intensity-based
  path already used.

- `PointProcess(tmin, tmax)` now creates an empty PointProcess
  (previously it only accepted an internal pointer and stopped
  otherwise). Backed by a new `pointprocess_module$create_empty()` C++
  factory wrapping Praat’s `PointProcess_create()`. Enables empty-object
  batch operations.

- `praat_eval_string_array("empty$# (n)")` segfaulted the R session. The
  vendored Praat `do_empty_STRVEC` built its result with
  `autoSTRVEC result { n }`, which zero-initialises the vector and so
  leaves every element a null pointer instead of a valid empty C string;
  the R wrapper’s `Melder_peek32to8()` then dereferenced null. It now
  returns `n` empty strings. Also un-skipped `formant$save()` (its
  earlier segfault was a symptom of the fixed `to_formant_burg()`
  crash).

- `Sound$get_optimal_formant_ceiling()` and `Sound$to_formant_optimal()`
  crashed the R session (SIGTRAP / “irrecoverable exception”) for every
  input. Two stacked causes were fixed. (1) The vendored Praat
  `Sound_to_Formant_common` read the null output `sound` instead of the
  local `resampled` when setting up the short-term analysis and
  Formant/LPC objects, crashing every Burg/robust formant-analysis entry
  point (`to_formant_burg()` was also broken). (2) The pladdrr
  `Formant_extractPart` stub wrote `newFrame->formant[]` without
  allocating it — `Formant_create` zeroes frames so the array is null —
  so the interval path aborted on the first dereference.
  `to_formant_burg()`, `to_formant_optimal()`, and
  `get_optimal_formant_ceiling()` now all work.

- [`autoplot.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md),
  [`autolayer.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md),
  and
  [`plot.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrogram.md)
  scrambled the frequency axis for any non-square spectrogram matrix (a
  [`expand.grid()`](https://rdrr.io/r/base/expand.grid.html)/[`as.vector()`](https://rdrr.io/r/base/vector.html)
  row/column-major mismatch — a 220 Hz tone rendered with its peak at
  2201 Hz), and plotted raw linear power directly as if already in dB,
  making the `dynamic_range` clipping parameter a silent no-op.

- [`plot_powercepstrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrogram.md)
  had the same two defects (time/quefrency-axis transposition and
  missing power-to-dB conversion), plus a hardcoded `max_time <- 5.0`
  placeholder in place of the cepstrogram’s real duration.

- [`plot_cpp_timeseries()`](https://humlab-speech.github.io/pladdrr/reference/plot_cpp_timeseries.md)
  used the same hardcoded-duration placeholder, and a
  [`tryCatch()`](https://rdrr.io/r/base/conditions.html) scoping bug
  (`cpp_values[i] <- NA` instead of `<<-` inside the error handler)
  meant a failed per-time-point CPP query silently became `0` instead of
  being dropped as `NA`.

- [`plot_powercepstrum()`](https://humlab-speech.github.io/pladdrr/reference/plot_powercepstrum.md)
  used a hardcoded `max_quefrency <- 0.05` placeholder instead of the
  cepstrum’s real quefrency range, and plotted its `power_dB` column
  (misleadingly named — the values are raw linear power, not dB) without
  converting, putting the line trace and its own peak-prominence marker
  on incompatible scales.

  None of these 5 functions had any test coverage before this release;
  12 new regression tests were added
  (`test-spectrogram-plot-regression.R`,
  `test-cepstrum-plots-regression.R`).

- Follow-up fixes closing the remaining `power_dB`-mislabel call sites:
  [`autoplot.PowerCepstrum()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)/[`autolayer.PowerCepstrum()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  and
  [`plot.PowerCepstrum()`](https://humlab-speech.github.io/pladdrr/reference/plot.PowerCepstrum.md)
  still plotted the C++
  [`as_data_frame()`](https://tibble.tidyverse.org/reference/deprecated.html)’s
  misleadingly-named `power_dB` column (raw linear power) directly under
  a “Power (dB)” axis, and selected their cepstral-peak marker with
  [`which.max()`](https://rdrr.io/r/base/which.min.html) on linear
  power. Both now convert to a real dB `power_db` column before plotting
  (5 new tests in `test-powercepstrum-db-regression.R`).

- `plot_powercepstrogram(show_cpp_contour = TRUE)` drew its CPP-contour
  overlay as a flat line at a hardcoded `quefrency = 0.01` placeholder;
  it now overlays the real per-time-frame cepstral-peak quefrency,
  computed as the argmax of each frame’s own raster row.

- [`plot.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrogram.md)’s
  `preemphasis` argument (default 50) was accepted but never referenced;
  removed as dead — pre-emphasis belongs in the DSP layer, not a plot
  method.

- [`plot_cpp_timeseries()`](https://humlab-speech.github.io/pladdrr/reference/plot_cpp_timeseries.md)
  no longer emits a cosmetic “Mean CPP: NaN dB (SD: NA)” subtitle when
  every sample fails; it now shows “No samples”.

- `PowerCepstrum$as_data_frame()` (the C++ `RPowerCepstrum` module)
  returned a column misleadingly named `power_dB` that actually held raw
  linear power; renamed to the honest `power`. This is a breaking change
  for any caller that read `$as_data_frame()$power_dB` directly; the
  affected plotting functions now read `power` and convert to
  `power_db`.

- [`as.data.frame.LPC()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  indexed the coefficient *matrix* as if it were a flat list
  (`coeffs[[i]]`), so it emitted one row per frame with a single
  mislabeled coefficient and silently dropped the other
  `maxnCoefficients - 1` coefficients of every frame. It now reads each
  frame’s coefficient column (`coeffs[, i]`), yielding one row per
  (frame, coefficient) as documented.

- `AmplitudeTier$to_intensity_tier()` and `AmplitudeTier$save()` called
  non-existent internal wrappers (`.amplitudetier_to_intensitytier()` /
  `.amplitudetier_save()`), so both errored with “could not find
  function”. They now dispatch through the Rcpp module
  (`to_intensity_tier_ptr()` /
  [`save()`](https://rdrr.io/r/base/save.html)). Six `get_shimmer_*()`
  AmplitudeTier methods were also removed: shimmer is a PointProcess
  metric (already present there), and these AmplitudeTier copies had no
  C++ implementation.

- [`plot_spectrogram_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_spectrogram_pitch.md)’s
  `freq_max` argument (documented “Maximum frequency to display”) was
  silently ignored — it was passed to
  [`plot.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrogram.md),
  which has no such parameter. It now maps to
  [`plot.Spectrogram()`](https://humlab-speech.github.io/pladdrr/reference/plot.Spectrogram.md)’s
  `to_freq`, so the frequency cap is honored.

- [`plot_sound_pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot_sound_pitch.md)’s
  `pitch_floor`/`pitch_ceiling` arguments were dead — passed to
  [`plot.Pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot.Pitch.md),
  which ignores them. Removed.

- Deprecated
  [`get_intensity_at_time()`](https://humlab-speech.github.io/pladdrr/reference/get_intensity_at_time.md)’s
  `interpolate` argument and
  [`create_sound()`](https://humlab-speech.github.io/pladdrr/reference/create_sound.md)’s
  `start_time` argument were silently ignored; both now forward to the
  underlying R6 methods.

- [`plot.Pitch()`](https://humlab-speech.github.io/pladdrr/reference/plot.Pitch.md)/[`autoplot.Pitch()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)’s
  `show_voicing` argument never colored by voicing strength: it looked
  for a `voicing_strength` column, but `Pitch$as_data_frame()` names it
  `strength` (and only includes it with `include_strength = TRUE`). Both
  now pull the strength column and color by it.

- [`autolayer.PointProcess()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)’s
  `ymin`/`ymax` arguments were ignored (it used `geom_vline`),
  [`autoplot.PCA()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)/[`autoplot.Discriminant()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)’s
  `garnish` argument was dead, and `.formant_colors()`’s `max_formant`
  was redundant. All now honor their documented behavior.

## pladdrr 5.0.1

### New features

- Added
  [`autoplot()`](https://ggplot2.tidyverse.org/reference/autoplot.html)
  and
  [`autolayer()`](https://ggplot2.tidyverse.org/reference/autolayer.html)
  S3 methods for 27 previously unsupported Praat object classes:
  AmplitudeTier, DurationTier, IntensityTier, PitchTier, FormantTier,
  FormantGrid, FormantPath, Excitation, ComplexSpectrogram, Cepstrum,
  Cochleagram, PowerCepstrogram, MFCC, LFCC, BarkSpectrogram,
  MelSpectrogram, Matrix, PCA, Discriminant, FormantModeler,
  Electroglottogram, LongSound, DTW, Polygon, VocalTract, LPC,
  KlattGrid.
- Added [`as.data.frame()`](https://rdrr.io/r/base/as.data.frame.html)
  S3 methods for 15 classes that lacked them.

### Bug fixes

- [`process_sounds_parallel()`](https://humlab-speech.github.io/pladdrr/reference/process_sounds_parallel.md)
  shipped already-loaded `Sound` objects directly to Windows PSOCK
  workers; their external pointer to the underlying C++ object cannot
  survive that process boundary, causing spurious errors on Windows with
  `n_cores > 1`. Sounds are now serialized to raw sample data and
  reconstructed inside each worker.
- Fixed `FormantGrid$as_data_frame()` missing required `time_step`
  argument.
- [`autoplot.KlattGrid()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)/[`as.data.frame.KlattGrid()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  passed a formant-type name as a string where the underlying accessor
  required an integer code, producing empty plots or silently wrong data
  for every formant type. Fixed to map the name to its integer code
  before dispatch; also corrected the shared `formant_type`
  documentation, which claimed `"all"` was an accepted value for
  [`autolayer.KlattGrid()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  when only
  [`autoplot.KlattGrid()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  actually supports it.
- [`as.data.frame.Cochleagram()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  always errored.
- [`as.data.frame.LPC()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  always errored, due to a typo’d `power_dB` column name that did not
  exist on the object.
- [`autolayer.DTW()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  plotted the wrong columns and crashed on some `NULL`-valued paths.
- `autoplot`/`autolayer`/`as.data.frame` for `Matrix`,
  `BarkSpectrogram`, and `MelSpectrogram` plotted raw row/column bin
  indices instead of the real time/frequency axis values.
- [`autoplot.Cepstrum()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  defaulted to a power-cepstrum dB view; Praat’s actual default is a raw
  signed quefrency-domain view. Fixed the default and added a `power`
  parameter to select the dB view explicitly.
- [`autoplot.ComplexSpectrogram()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  and
  [`autolayer.ComplexSpectrogram()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  both mislabeled linear amplitude values as dB and ignored
  `dynamic_range`.
- [`as.data.frame.VocalTract()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md),
  [`autoplot.VocalTract()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md),
  and
  [`autolayer.VocalTract()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  all hardcoded section spacing (`dx`) instead of reading it from the
  object, giving wrong x-axis values whenever spacing was non-default.
- [`autoplot.FormantTier()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)/[`autolayer.FormantTier()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  defaulted to an interpolated line view; Praat’s actual default view is
  speckle (points).
- [`autoplot.FormantPath()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  and
  [`autoplot.FormantModeler()`](https://humlab-speech.github.io/pladdrr/reference/autoplot-methods.md)
  always produced empty plots — the former from a column-name mismatch,
  the latter from a wide/long data-frame format mismatch.
- [`as.data.frame.PowerCepstrogram()`](https://humlab-speech.github.io/pladdrr/reference/as-data-frame-missing.md)
  called a nonexistent `$as_data_frame()` method and always crashed;
  fixed to route through `$to_matrix()`.
- `Sound$extract_electroglottogram()` was never registered in the R6
  method table, despite its underlying C++ export existing and being
  registered; every call crashed with “attempt to apply non-function”.

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
