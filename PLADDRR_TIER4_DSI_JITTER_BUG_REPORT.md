# pladdrr bug report: `get_voice_quality_ultra()` hardcodes wrong pitch algorithm for jitter

**Component:** Tier 4 "Ultra" batch API — `get_voice_quality_ultra()` / `get_voice_quality_ultra_cpp`
**Files:** `R/batch-queries.R` (R wrapper), `src/batch_queries.cpp:1129-1215` (C++ core)
**Severity:** Correctness (silent, no error/warning) — accuracy regression vs Praat, not a crash
**Found via:** plabench's `tests/test_3way_validation.py::TestDSI3Way` (Praat vs Python vs R), 2026-07-29

## Summary

`get_voice_quality_ultra_cpp()` unconditionally extracts pitch with
`Sound_to_Pitch_rawCc(..., veryAccurate=true)` — the **cross-correlation**
method — for every metric it's asked to compute (jitter, shimmer, HNR). But
Praat's own plain `To Pitch...` command (the one most existing scripts,
including this one, actually use) dispatches to `Sound_to_Pitch_rawAc` — the
**autocorrelation** method, with `veryAccurate=false`. These are genuinely
different DSP algorithms (different window factors, different candidate
selection), not just different parameter values. There is no argument on
`get_voice_quality_ultra()`'s R-level signature (`sound, metrics, min_pitch,
max_pitch, time_step`) that lets a caller select AC instead of CC, so any
caller whose reference algorithm uses plain `To Pitch...` cannot get a
matching result out of this API no matter what they pass.

## Evidence

### 1. Praat's plain `To Pitch...` resolves to the AC method, not CC

`src/praat.github.io/fon/Sound_to_Pitch.cpp` — the handler backing the
3-argument `To Pitch...` command (`Sound_to_Pitch`, no `(cc)`/`(ac)` suffix)
calls:

```cpp
return Sound_to_Pitch_rawAc (me, timeStep, pitchFloor, pitchCeiling,
    15, false, 0.03, 0.45, 0.01, 0.35, 0.14);
```

i.e. autocorrelation, `veryAccurate = false`. This is what runs whenever a
script says `To Pitch... <timeStep> <floor> <ceiling>` with no `(cc)`/`(ac)`
qualifier — which is exactly what the DSI jitter step does.

### 2. Praat's own DSI script uses plain `To Pitch...` for the jitter block

`original_implementations/praat/DSI/DSI201.praat:204`:

```praat
To Pitch... 0 70 600
select Sound ppq2
plus Pitch ppq2
To PointProcess (cc)
...
voiceReport$ = Voice report... 0 0 70 600 1.3 1.6 0.03 0.45
jitterPpq5Pre = extractNumber (voiceReport$, "Jitter (ppq5): ")
```

Note: the *Pitch* extraction is plain (AC, not cc) — only the subsequent
*PointProcess* creation uses `(cc)`, which combines the already-AC-derived
Pitch object with the Sound to place voicing pulses. This two-stage
AC-pitch-then-cc-pointprocess pattern is Praat's actual algorithm for this
measurement.

Plabench's Python port mirrors this exactly (`reimplementations/parselmouth_python/DSI/dsi.py:257-261`):

```python
pitch = call(sound_extract, "To Pitch", 0, 70, 600)   # AC, veryAccurate=false
point_process = call([sound_extract, pitch], "To PointProcess (cc)")
```

### 3. pladdrr's Tier-4 core hardcodes the CC method instead

`src/batch_queries.cpp:1141-1146` (`get_voice_quality_ultra_cpp`):

```cpp
autoPitch pitch = Sound_to_Pitch_rawCc(
    sound.get(), time_step, min_pitch, max_pitch, 15, true,
    0.03, 0.45, 0.01, 0.35, 0.14
);
autoPointProcess pp = Sound_Pitch_to_PointProcess_cc(sound.get(), pitch.get());
```

This is cross-correlation pitch extraction with `veryAccurate = true` — two
algorithmic choices, made unconditionally in C++, that diverge from what the
plain `To Pitch...` command Praat/Python actually use for this measurement
produces. (The subsequent `PointProcess (cc)` step is correct/matching — the
divergence is entirely upstream, in which *Pitch* object gets fed into it.)

Everything else in this function — `period_floor=0.0001`, `period_ceiling=0.02`,
`max_period_factor=1.3`, `max_amplitude_factor=1.6`, and the pitch-extraction
threshold params `0.03, 0.45, 0.01, 0.35, 0.14` — are Praat's own standard
defaults and correctly match what `DSI201.praat`'s `Voice report...` call
uses. **The bug is specifically the AC-vs-CC + veryAccurate algorithm choice,
not parameter tuning.**

## Measured impact

From plabench's live 3-way validation (`results/validations_260729.txt`,
`TestDSI3Way`, same input file for all three):

| Implementation | Jitter ppq5 | Abs. error vs Praat |
|---|---|---|
| Praat (reference) | 0.300% | — |
| Python (`To Pitch` / AC, matches Praat's algorithm) | 0.297% | 0.003% |
| R / pladdrr Tier-4 `get_voice_quality_ultra()` (CC, veryAccurate) | 0.282% | 0.018% |

R's error is **~6x Python's**, though both currently pass under the test's
±0.05% tolerance. The gap is fully attributable to a different Pitch object
being fed into an otherwise-correct `PointProcess (cc)` + `Voice report` pipeline.

## Suggested fix

Either:
- Add a `pitch_method` (e.g. `"ac"` / `"cc"`) and `very_accurate` parameter to
  `get_voice_quality_ultra()` / `get_voice_quality_ultra_cpp`, defaulting to
  whatever preserves current behavior, so callers whose reference algorithm
  uses plain `To Pitch...` can opt into `Sound_to_Pitch_rawAc(..., false, ...)`
  instead of the hardcoded `Sound_to_Pitch_rawCc(..., true, ...)`; or
- Document explicitly (Roxygen + vignette) that `get_voice_quality_ultra()`
  always uses CC/veryAccurate pitch internally, so downstream authors know
  not to reach for it when their ground truth is Praat's plain `To Pitch...`.

## plabench-side status

No change made to `reimplementations/pladdrr_R/DSI/dsi.R` — per project
decision, `calculate_jitter_ppq5()` continues to use the Tier-4
`get_voice_quality_ultra()` API for its 3.6x speed advantage, accepting the
current in-tolerance (0.018% abs, ~6% relative) accuracy gap as a known
limitation pending a pladdrr-side fix in a future release. If pladdrr adds a
way to select AC/veryAccurate=false pitch extraction, `dsi.R` should be
revisited to pass it.
