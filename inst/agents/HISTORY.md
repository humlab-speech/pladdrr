# pladdrr Version History

**Maintained by:** coding agents and maintainers
**Purpose:** Superseded patterns, historical version archive, SIMD implementation history.

---

## Recent Changes

See `AGENT_GUIDE.md` sections "What's New in v4.9.x" (line 85) and "What's New in v4.8.x" (line 124) for recent feature additions and breaking changes.

## Historical Archive

See `AGENT_GUIDE.md` section "Version History (historical archive)" (line 4214) for the full version history from v1.0 through v4.7.x.

## Superseded SIMD Patterns

See `AGENT_GUIDE.md` section "Historical SIMD and performance archive (superseded)" (line 4556) for documentation of SIMD implementation patterns that are no longer the recommended approach.

---

## Key Breaking Changes

- **v4.9.18:** CPPS trend-fit fusion (`PowerCepstrogram_getCPPS_fused`) for ~2x CPPS speedup (gated behind `fused=FALSE` default). SIMD bridge small-input scalar fallback (`n<16`). Custom `parallel_for_range` thread pool replaced with `MelderThread_PARALLELIZE`. Bridge functions re-marked `@keywords internal`. Frequency unit codes centralized through `unit_to_code()`. Faithfulness test coverage expanded (5→11 routines). Agent docs split: `ARCHITECTURE.md` + `HISTORY.md` extracted from `AGENT_GUIDE.md`.
- **v4.9.10:** `max_quefrency` and `tilt_line_quefrency` parameters now actually honored by the C++ core. Previously hardcoded to [0.003, 0.04]. AVQI CPPS values may shift by ~0.3 dB.
- **v4.9.9:** SIMD now compiled by default (`-DHAVE_XSIMD`). All 32 SIMD files active.
- **v4.8.32-33:** Shared dispatch table pattern introduced. Phase 3 migration from module dispatch to wrapper dispatch (30-40% per-call improvement).
- **v4.6.4:** CPPS parameter defaults aligned with `calculate_cpps_fast()`. Added `pre_emphasis_from` and `max_frequency` parameters.
- **v4.0.7:** MFCC, LFCC, FormantModeler, PCA, Discriminant modules added.
- **v4.0.4:** LTAS unit codes fixed to match Praat's `kLtas_unit` enum.
