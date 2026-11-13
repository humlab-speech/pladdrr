# Dead-code audit: goodpractice `complexity_unused_internal` (2026-11)

Package pladdrr 5.x, branch `worktree-agent-ab00b4481f290b01c`. Check source: `goodpractice:::CHECKS$complexity_unused_internal`
(internal = defined top-level function not in NAMESPACE exports / S3 registrations / package hooks, and not referenced
by any call in the parsed R code). Reproduce with `goodpractice::gp(".", checks = "complexity_unused_internal")`.

## Result

- Findings: 119. SAFE-DELETE: 0. KEEP: 110. UNSURE: 9.
- Nothing deleted. All 119 are false positives of the static check or generated Rcpp bindings.

## Why they are flagged but alive

- 45 `$.<Class>` methods: registered with `S3method("$", Class)`; the check's S3-name resolver does not match the `$` generic, and `x$member` is not a call.
- 30 `pladdrr_shared_*`: roxygen-only parameter-doc anchors consumed by `@inheritParams` (no runtime role).
- 44 `R/RcppExports.R` bindings: generated. 35 are used by R code and/or tests (`pladdrr:::` calls, e.g. `.table_*` via table-wrapper.R:39). 9 have no R/test/doc reference at all (marked UNSURE): their C++ functions are `// [[Rcpp::export]]` in src/ and may be called C++-internally. Removing them means editing src/ and regenerating RcppExports; prior history (6 R-dead-but-C++-alive caught by a linker failure) argues for a separate, build-verified change.

## Checks applied to every candidate

Textual grep (word-boundary) across R/ (excluding the definition), src/ (non-vendored .cpp/.h), tests/, inst/, vignettes/, dev/, man/, NAMESPACE, _pkgdown.yml, .github/; NAMESPACE `S3method` registration; Rcpp export linkage (symbol in R/RcppExports.R body vs src/*.cpp); roxygen `@rdname`/`@inheritParams` use. No dynamic-name construction (paste0/sprintf/do.call/get/match.fun) is needed for any flagged name: S3 methods dispatch via NAMESPACE, anchors are roxygen-only, bindings are `.Call` wrappers.

## Classification table

| Candidate | File:line | Verdict | Evidence |
|---|---|---|---|
| `$.AmplitudeTier` | R/amplitudetier-wrapper.R:138 | KEEP | S3 method for `$`; `S3method("$",AmplitudeTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Cepstrum` | R/cepstrum-wrapper.R:73 | KEEP | S3 method for `$`; `S3method("$",Cepstrum)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Cochleagram` | R/cochleagram-wrapper.R:146 | KEEP | S3 method for `$`; `S3method("$",Cochleagram)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.ComplexSpectrogram` | R/complexspectrogram-module.R:76 | KEEP | S3 method for `$`; `S3method("$",ComplexSpectrogram)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Discriminant` | R/discriminant-wrapper.R:145 | KEEP | S3 method for `$`; `S3method("$",Discriminant)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.DurationTier` | R/durationtier-wrapper.R:108 | KEEP | S3 method for `$`; `S3method("$",DurationTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Electroglottogram` | R/electroglottogram-wrapper.R:142 | KEEP | S3 method for `$`; `S3method("$",Electroglottogram)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Excitation` | R/excitation-wrapper.R:102 | KEEP | S3 method for `$`; `S3method("$",Excitation)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Formant` | R/formant-wrapper.R:342 | KEEP | S3 method for `$`; `S3method("$",Formant)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.FormantGrid` | R/formantgrid-wrapper.R:155 | KEEP | S3 method for `$`; `S3method("$",FormantGrid)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.FormantModeler` | R/formantmodeler-wrapper.R:153 | KEEP | S3 method for `$`; `S3method("$",FormantModeler)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.FormantPath` | R/formantpath-module.R:175 | KEEP | S3 method for `$`; `S3method("$",FormantPath)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.FormantTier` | R/formanttier-wrapper.R:134 | KEEP | S3 method for `$`; `S3method("$",FormantTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.formanttier_constructor` | R/formanttier-wrapper.R:188 | KEEP | S3 method for `$`; `S3method("$",formanttier_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Harmonicity` | R/harmonicity.R:199 | KEEP | S3 method for `$`; `S3method("$",Harmonicity)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Intensity` | R/intensity-wrapper.R:246 | KEEP | S3 method for `$`; `S3method("$",Intensity)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.IntensityTier` | R/intensitytier-wrapper.R:97 | KEEP | S3 method for `$`; `S3method("$",IntensityTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.KlattGrid` | R/klattgrid-module.R:154 | KEEP | S3 method for `$`; `S3method("$",KlattGrid)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.LongSound` | R/longsound-wrapper.R:213 | KEEP | S3 method for `$`; `S3method("$",LongSound)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.longsound_constructor` | R/longsound-wrapper.R:313 | KEEP | S3 method for `$`; `S3method("$",longsound_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.LPC` | R/lpc-wrapper.R:198 | KEEP | S3 method for `$`; `S3method("$",LPC)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Ltas` | R/ltas-wrapper.R:364 | KEEP | S3 method for `$`; `S3method("$",Ltas)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Manipulation` | R/manipulation-wrapper.R:122 | KEEP | S3 method for `$`; `S3method("$",Manipulation)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Matrix` | R/matrix-wrapper.R:105 | KEEP | S3 method for `$`; `S3method("$",Matrix)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.MFCC` | R/mfcc-wrapper.R:202 | KEEP | S3 method for `$`; `S3method("$",MFCC)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.LFCC` | R/mfcc-wrapper.R:343 | KEEP | S3 method for `$`; `S3method("$",LFCC)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.PCA` | R/pca-wrapper.R:121 | KEEP | S3 method for `$`; `S3method("$",PCA)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.PitchModule` | R/pitch-module.R:247 | KEEP | S3 method for `$`; `S3method("$",PitchModule)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Pitch` | R/pitch-wrapper.R:345 | KEEP | S3 method for `$`; `S3method("$",Pitch)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.PitchTier` | R/pitchtier-wrapper.R:344 | KEEP | S3 method for `$`; `S3method("$",PitchTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.pitchtier_constructor` | R/pitchtier-wrapper.R:406 | KEEP | S3 method for `$`; `S3method("$",pitchtier_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `pladdrr_shared_params` | R/pladdrr-package.R:230 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 229 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_method_name` | R/pladdrr-package.R:250 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_sound` | R/pladdrr-package.R:259 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 16 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_time0` | R/pladdrr-package.R:268 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 16 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_sound_r6` | R/pladdrr-package.R:278 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 11 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_sound_a` | R/pladdrr-package.R:286 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 10 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_pitch` | R/pladdrr-package.R:295 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 9 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_pitch_r6` | R/pladdrr-package.R:304 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 9 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_sound_legacy` | R/pladdrr-package.R:312 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 8 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_timeauto` | R/pladdrr-package.R:320 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 7 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_textgrid_r6` | R/pladdrr-package.R:329 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 8 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_pitch_a` | R/pladdrr-package.R:338 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 7 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_maxformant` | R/pladdrr-package.R:346 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 7 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_dots_plot` | R/pladdrr-package.R:354 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 26 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_timeauto75` | R/pladdrr-package.R:362 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 7 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_analysis` | R/pladdrr-package.R:382 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 26 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_minpitch` | R/pladdrr-package.R:396 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 8 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_maxpitch` | R/pladdrr-package.R:406 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_formant_obj` | R/pladdrr-package.R:416 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_harmonicity_obj` | R/pladdrr-package.R:425 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 5 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_intensity_obj` | R/pladdrr-package.R:434 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_intensity_r6` | R/pladdrr-package.R:444 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 5 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_ltas_obj` | R/pladdrr-package.R:453 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 5 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_pointprocess_obj` | R/pladdrr-package.R:461 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 5 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_powercepstrum_obj` | R/pladdrr-package.R:470 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_spectrogram_obj` | R/pladdrr-package.R:480 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 7 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_spectrum_obj` | R/pladdrr-package.R:490 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 6 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_textgrid_obj` | R/pladdrr-package.R:499 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 4 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_autoplot_object` | R/pladdrr-package.R:514 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 15 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `pladdrr_shared_praat_sound_obj` | R/pladdrr-package.R:524 | KEEP | roxygen `@rdname`/`@inheritParams` anchor; 8 textual refs (roxygen blocks, man/*.Rd); not runtime code |
| `$.PointProcess` | R/pointprocess-wrapper.R:475 | KEEP | S3 method for `$`; `S3method("$",PointProcess)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Polygon` | R/polygon-module.R:117 | KEEP | S3 method for `$`; `S3method("$",Polygon)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.PowerCepstrum` | R/powercepstrum.R:292 | KEEP | S3 method for `$`; `S3method("$",PowerCepstrum)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.PowerCepstrogram` | R/powercepstrum.R:488 | KEEP | S3 method for `$`; `S3method("$",PowerCepstrogram)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `pitch_get_statistics_batch` | R/RcppExports.R:155 | KEEP | generated binding for `pitch_get_statistics_batch`; referenced from R/tests/docs: test-batch-queries.R:365 test-batch-queries.R:390 test-batch-queries.R:398 |
| `intensity_get_statistics_batch` | R/RcppExports.R:201 | KEEP | generated binding for `intensity_get_statistics_batch`; referenced from R/tests/docs: test-batch-queries.R:369 test-batch-queries.R:446 test-batch-queries.R:453 |
| `intensity_get_minimum_with_time` | R/RcppExports.R:217 | KEEP | generated binding for `intensity_get_minimum_with_time`; referenced from R/tests/docs: test-batch-queries.R:371 test-batch-queries.R:424 test-batch-queries.R:431 |
| `.formantgrid_create_empty` | R/RcppExports.R:666 | KEEP | generated binding for `formantgrid_create_empty`; referenced from R/tests/docs: test-formantgrid-r6.R:109 |
| `.sound_formantgrid_filter` | R/RcppExports.R:682 | KEEP | generated binding for `sound_formantgrid_filter`; referenced from R/tests/docs: test-formantgrid-r6.R:131 |
| `.lpc_sound_filter_inverse` | R/RcppExports.R:871 | KEEP | generated binding for `lpc_sound_filter_inverse`; referenced from R/tests/docs: test-lpc-module-gaps.R:208 test-lpc-module-gaps.R:209 test-lpc-module-gaps.R:221 |
| `.matrix_from_r_matrix` | R/RcppExports.R:967 | KEEP | generated binding for `matrix_from_r_matrix`; referenced from R/tests/docs: test-simd-matrix.R:9 test-simd-matrix.R:11 |
| `sound_get_duration_direct` | R/RcppExports.R:1127 | KEEP | generated binding for `sound_get_duration_direct`; referenced from R/tests/docs: test-direct-class-guard.R:3 test-direct-class-guard.R:13 test-direct-class-guard.R:23 |
| `sound_get_rms_direct` | R/RcppExports.R:1140 | KEEP | generated binding for `sound_get_rms_direct`; referenced from R/tests/docs: test-direct-class-guard.R:13 test-direct-class-guard.R:24 |
| `pitch_get_minimum_direct` | R/RcppExports.R:1202 | KEEP | generated binding for `pitch_get_minimum_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:63 |
| `pitch_get_maximum_direct` | R/RcppExports.R:1218 | KEEP | generated binding for `pitch_get_maximum_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:68 |
| `pitch_count_voiced_direct` | R/RcppExports.R:1248 | KEEP | generated binding for `pitch_count_voiced_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:72 |
| `formant_get_bandwidth_direct` | R/RcppExports.R:1278 | KEEP | generated binding for `formant_get_bandwidth_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:99 |
| `formant_get_mean_direct` | R/RcppExports.R:1295 | KEEP | generated binding for `formant_get_mean_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:104 |
| `intensity_get_mean_direct` | R/RcppExports.R:1326 | KEEP | generated binding for `intensity_get_mean_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:76 AGENT_GUIDE.md:727 |
| `intensity_get_minimum_direct` | R/RcppExports.R:1341 | KEEP | generated binding for `intensity_get_minimum_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:81 |
| `intensity_get_maximum_direct` | R/RcppExports.R:1356 | KEEP | generated binding for `intensity_get_maximum_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:82 |
| `harmonicity_get_value_direct` | R/RcppExports.R:1369 | KEEP | generated binding for `harmonicity_get_value_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:92 |
| `harmonicity_get_mean_direct` | R/RcppExports.R:1384 | KEEP | generated binding for `harmonicity_get_mean_direct`; referenced from R/tests/docs: test-praat-direct-parity.R:87 |
| `get_point_process_mean_period_direct` | R/RcppExports.R:1483 | UNSURE | generated binding for `get_point_process_mean_period_direct`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `get_point_process_stdev_period_direct` | R/RcppExports.R:1496 | UNSURE | generated binding for `get_point_process_stdev_period_direct`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `sound_stats` | R/RcppExports.R:1536 | UNSURE | generated binding for `sound_stats`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `get_sound_duration_cpp` | R/RcppExports.R:1568 | UNSURE | generated binding for `get_sound_duration_cpp`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `get_sound_sampling_rate_cpp` | R/RcppExports.R:1584 | UNSURE | generated binding for `get_sound_sampling_rate_cpp`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `get_sound_n_samples_cpp` | R/RcppExports.R:1600 | UNSURE | generated binding for `get_sound_n_samples_cpp`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `sound_pool_acquire` | R/RcppExports.R:1818 | KEEP | generated binding for `sound_pool_acquire`; referenced from R/tests/docs: test-sound-pool-contracts.R:12 test-sound-pool-contracts.R:23 test-sound-pool-contracts.R:39 |
| `sound_pool_release` | R/RcppExports.R:1834 | KEEP | generated binding for `sound_pool_release`; referenced from R/tests/docs: test-sound-pool-contracts.R:18 test-sound-pool-contracts.R:29 test-sound-pool-contracts.R:41 |
| `.sound_to_pitch` | R/RcppExports.R:1951 | UNSURE | generated binding for `sound_to_pitch`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `.sound_to_intensity` | R/RcppExports.R:1986 | UNSURE | generated binding for `sound_to_intensity`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `.formant_get_values_at_times` | R/RcppExports.R:2343 | KEEP | generated binding for `formant_get_values_at_times`; referenced from R/tests/docs: AGENT_GUIDE.md:362 |
| `.table_get_numeric_value` | R/RcppExports.R:2631 | KEEP | generated binding for `table_get_numeric_value`; referenced from R/tests/docs: table-wrapper.R:39 test-table-wrapper.R:182 test-table-wrapper.R:183 |
| `.table_set_numeric_value` | R/RcppExports.R:2639 | KEEP | generated binding for `table_set_numeric_value`; referenced from R/tests/docs: test-table-wrapper.R:148 test-table-wrapper.R:149 test-table-wrapper.R:150 |
| `.table_remove_row` | R/RcppExports.R:2643 | KEEP | generated binding for `table_remove_row`; referenced from R/tests/docs: test-table-wrapper.R:178 test-table-wrapper.R:213 test-table-wrapper.R:215 |
| `.table_remove_column` | R/RcppExports.R:2647 | KEEP | generated binding for `table_remove_column`; referenced from R/tests/docs: test-table-wrapper.R:175 test-table-wrapper.R:213 test-table-wrapper.R:216 |
| `.table_insert_column` | R/RcppExports.R:2651 | KEEP | generated binding for `table_insert_column`; referenced from R/tests/docs: test-table-wrapper.R:172 test-table-wrapper.R:213 test-table-wrapper.R:218 |
| `.table_get_minimum` | R/RcppExports.R:2663 | KEEP | generated binding for `table_get_minimum`; referenced from R/tests/docs: test-table-wrapper.R:152 test-table-wrapper.R:205 |
| `.table_get_maximum` | R/RcppExports.R:2667 | KEEP | generated binding for `table_get_maximum`; referenced from R/tests/docs: test-table-wrapper.R:154 test-table-wrapper.R:206 |
| `.table_get_sum` | R/RcppExports.R:2671 | KEEP | generated binding for `table_get_sum`; referenced from R/tests/docs: test-table-wrapper.R:156 test-table-wrapper.R:207 |
| `.table_get_quantile` | R/RcppExports.R:2675 | KEEP | generated binding for `table_get_quantile`; referenced from R/tests/docs: test-table-wrapper.R:158 test-table-wrapper.R:208 |
| `.table_get_column_numbers` | R/RcppExports.R:2679 | KEEP | generated binding for `table_get_column_numbers`; referenced from R/tests/docs: test-table-wrapper.R:165 |
| `.table_to_matrix` | R/RcppExports.R:2687 | KEEP | generated binding for `table_to_matrix`; referenced from R/tests/docs: test-table-wrapper.R:161 |
| `.pladdrr_cpus_for_limits` | R/RcppExports.R:3219 | KEEP | generated binding for `pladdrr_cpus_for_limits`; referenced from R/tests/docs: test-affinity-thread-count.R:7 test-affinity-thread-count.R:8 PRAAT_MODIFICATIONS.md:63 |
| `.pladdrr_thread_grains_cpp` | R/RcppExports.R:3243 | KEEP | generated binding for `pladdrr_thread_grains_cpp`; referenced from R/tests/docs: test-thread-granularity.R:26 |
| `praat_error_to_r` | R/RcppExports.R:3262 | UNSURE | generated binding for `praat_error_to_r`; zero refs in R/, tests/, inst/, vignettes/, dev/. Removal needs src/ edit + compileAttributes() (out of scope; history: 6 of 246 earlier removals were C++-alive) |
| `$.Sound` | R/sound-wrapper.R:1180 | KEEP | S3 method for `$`; `S3method("$",Sound)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.sound_constructor` | R/sound-wrapper.R:1457 | KEEP | S3 method for `$`; `S3method("$",sound_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Spectrogram` | R/spectrogram-wrapper.R:214 | KEEP | S3 method for `$`; `S3method("$",Spectrogram)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Spectrum` | R/spectrum-wrapper.R:306 | KEEP | S3 method for `$`; `S3method("$",Spectrum)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.SpectrumTier` | R/spectrumtier-wrapper.R:126 | KEEP | S3 method for `$`; `S3method("$",SpectrumTier)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.Table` | R/table-wrapper.R:214 | KEEP | S3 method for `$`; `S3method("$",Table)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.TextGrid` | R/textgrid-wrapper.R:499 | KEEP | S3 method for `$`; `S3method("$",TextGrid)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.textgrid_constructor` | R/textgrid-wrapper.R:553 | KEEP | S3 method for `$`; `S3method("$",textgrid_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.VocalTract` | R/vocaltract-wrapper.R:134 | KEEP | S3 method for `$`; `S3method("$",VocalTract)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
| `$.vocaltract_constructor` | R/vocaltract-wrapper.R:201 | KEEP | S3 method for `$`; `S3method("$",vocaltract_constructor)` in NAMESPACE; invoked implicitly by `x$member` (no literal call exists) |
