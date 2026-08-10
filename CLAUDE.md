# pladdrr — CLAUDE.md

R package: OO interface to Praat phonetic analysis via Rcpp. Wraps Praat
C++ (from `praat.github.io/`) with R6 classes.

## Build

``` bash
R CMD INSTALL .
# or faster:
R CMD INSTALL --no-docs .
```

**Always edit both `src/Makevars` AND `src/Makevars.in`** for build
changes — `configure` regenerates `Makevars` from `Makevars.in` on every
install.

- `src/Makevars.win` compiles from the same `praat.github.io/` prefix as
  Unix (the old `src/praat/` duplicate tree was removed in the CRAN
  slimming)
- `-DPLADDRR_FULL_PRAAT` \#ifdef’s out stubs in `praat_stubs.cpp`
- Praat uses `macintosh` macro (not `__APPLE__`) — never define globally
  (triggers ObjC includes)

## Source layout

    src/                    # C++ wrappers + Rcpp exports
      batch_queries.cpp     # CPPS, AVQI, batch ops — threaded
      *_wrappers.cpp        # Praat object wrappers
      *_stubs.cpp           # Minimal stubs for unused Praat code
      *_simd.cpp            # SIMD-optimized paths
    praat.github.io/        # Praat source (submodule)
    R/
      performance-helpers.R # get_cpps_fast(), to_powercepstrogram_fast()
      *.R                   # R6 class definitions

## Threading

`MelderThread` fully implemented (not stubbed). Key threaded paths: -
`Sound_to_PowerCepstrogram`: `MelderThread_PARALLELIZE`, threshold=40
frames - `PowerCepstrogram_to_Matrix_CPP`: `SampledIntoSampled_mt` -
`PowerCepstrogram_smooth_fast`: parallelized `Sampled_getMean`

## Critical API notes

- Sound R6 lazy fields (`duration`, `nx`, `dx`) return empty — use
  methods (`$get_total_duration()`)
- [`to_point_process_direct()`](https://humlab-speech.github.io/pladdrr/reference/to_point_process_direct.md)
  arg order:
  `(sound, pitch_floor, pitch_ceiling, time_step=0, max_period_factor, max_amplitude_factor)`
- [`get_jitter_shimmer_batch()`](https://humlab-speech.github.io/pladdrr/reference/get_jitter_shimmer_batch.md)
  returns all 6 shimmer metrics in one C++ call

## CPPS parameter defaults

| Context | time_avg | quefrency_avg | pitch_ceiling | line_type |
|----|----|----|----|----|
| R6 `get_cpps()` | 0.001 | 0.0005 | 333.3 | straight (1) |
| [`get_cpps_fast()`](https://humlab-speech.github.io/pladdrr/reference/get_cpps_fast.md) (AVQI) | 0.01 | 0.001 | 333.3 | straight (1) |

`calculate_cpps_ultra_cpp` matches R6 defaults.
