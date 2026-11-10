# Faithfulness Report (pladdrr vs Praat)

_Generated: 2026-11-09 21:00:18 CET_

Each row is one Praat DSP routine. Praat output is the oracle; pladdrr
is checked against it at the documented tolerance. `pass` = within
tolerance, `fail` = drift (open an issue or document the rationale).

A routine with several values shows its first value; |Δ| is the largest
over all of them (`n` = number of values).

| Routine | Status | n | Praat | pladdrr | |Δ| | Tolerance |
|---------|--------|---|-------|---------|------|-----------|
| Sound$get_total_duration | pass | 1 | 1 | 1 | 0 | 0 |
| Sound$get_number_of_samples | pass | 1 | 44100 | 44100 | 0 | 0 |
| Sound -> Pitch (cc) -> mean F0 (Hz) | pass | 1 | 440.0102 | 440.0102 | 8.6402e-12 | 1e-04 |
| Sound -> Intensity -> mean (dB) | pass | 1 | 84.94803 | 84.94803 | 3.075786e-07 | 1e-06 |
| Sound -> Formant (burg) -> F1@0.5s (Hz) | pass | 1 | 420.6684 | 420.6684 | 5.633183e-11 | 0.001 |
| CPPS (calculate_cpps_ultra) | pass | 1 | 9.923184 | 9.920529 | 0.002654309 | 0.005 |
| Pitch (AC) -> mean F0 (Hz) | pass | 1 | 440.0102 | 440.0102 | 9.549694e-12 | 1e-04 |
| Pitch (SHS) -> mean F0 (Hz) | pass | 1 | 440.8181 | 440.8181 | 5.684342e-14 | 1e-04 |
| Intensity -> mean (energy-averaged, dB) | pass | 1 | 84.94803 | 84.94803 | 3.075826e-07 | 1e-05 |
| Formant (keepAll) -> F1@0.5s (Hz) | pass | 1 | 0 | 0 | 0 | 0.001 |
| Harmonicity (cc) -> mean (dB) | pass | 1 | 91.86342 | 91.8635 | 8.164053e-05 | 1e-04 |
| Spectrogram -> power at (0.5 s, 1000 Hz) | pass | 1 | 3.131686e-05 | 3.131686e-05 | 2.236167e-19 | 1e-09 |
| PointProcess (cc) -> jitter local | pass | 1 | 8.023673e-07 | 8.023673e-07 | 1.787663e-18 | 1e-09 |
| MFCC -> number of frames | pass | 1 | 195 | 195 | 0 | 0 |
| MFCC -> coefficients c1..c12, frames 1, 40, 100 | pass | 36 | 376.0016 | 376.0016 | 2.456773e-10 | 1e-06 |
| Sound$get_sampling_frequency | pass | 1 | 44100 | 44100 | 0 | 0 |
| Sound$get_number_of_channels | pass | 1 | 1 | 1 | 0 | 0 |
| Sound$get_mean | pass | 1 | 0 | 0 | 0 | 1e-12 |
| Sound$get_rms | pass | 1 | 0.3535251 | 0.3535251 | 0 | 1e-12 |
| Sound -> FormantPath -> Path finder -> mean F1, F2 (Hz) | pass | 2 | 598.5102 | 598.5102 | 1.364242e-12 | 1e-06 |

**Non-determinism caveat (CPPS row above):** the tolerance reported for
`CPPS (calculate_cpps_ultra)` reflects the deterministic fast/default
trend-fit path (`fit_method = "robust"`, Siegel). Praat's own
`fit_method = "robust slow"` (Theil-Sen) trend fit is **not**
deterministic — a documented upstream Praat defect — and samples
randomly: ~0.8 dB spread across identical runs of the same input, with
occasional extreme outliers around `1e290`. pladdrr reproduces that
non-determinism faithfully when `"robust slow"` is requested (see
`AGENT_GUIDE.md` v4.9.19 entry and `PRAAT_MODIFICATIONS.md` v4.9.19).
Do not read the row above as evidence that the robust-slow path is
bit-reproducible — it is not, in Praat or in pladdrr.

**Oracle version (CPPS row above):** the CPPS row agrees with Praat 6.4.47 to
0.003 dB. Against Praat 6.4.27 the same pipeline differs by about +0.13 dB:
Praat rewrote its CPP-to-CPPS post-processing between those releases
(`max(raw) - trend` became `max(raw - trend)`, and the robust trend estimator
changed), so a gap of that size against an older oracle is a version
difference, not a pladdrr defect. Say which Praat produced a reference number.

**Oracle version (FormantPath rows):** the 2026-11 external review ran this
registry against Praat 6.4.27 and found the mean F1 / F2 rows off by 0.138 Hz /
0.0256 Hz, with identical frame count and step; it attributed that to the
candidate-grid origin (0 in 6.4.27, 0.0275 s in the 6.4.47 code vendored here).
Those figures were not reproduced against 6.4.27 here; against 6.4.47 the rows
pass. Treat a gap of that size against an older oracle as a version difference,
and do not widen the tolerance for it: the same tolerance guards real drift.

**MFCC rows:** Praat's `To MFCC` takes (first filter, distance, max) where
`Sound$to_mfcc()` takes (`f1_mel`, `fmax_mel`, `df_mel`). The frame-count row
passed while the two were crossed, so the coefficient row exists to catch a
wrong mapping; against 6.4.47 the coefficients agree to about 2.5e-10.

**Platform caveat (Intensity row above):** on Apple Silicon the reference
Praat application and pladdrr can differ by ~2e-6 dB in an energy-averaged
Intensity mean at the default time step (measured against Praat 6.4.47 with
byte-identical input: 87.415718735 vs 87.415720871; every other step size
tried agrees to all printed digits, and the 2026-11 audit found Linux x86-64 agreeing against Praat 6.4.27). Frame centres
`x1 + (i-1)*dx` land exactly on a rounding boundary of
`Sampled_xToNearestIndex` for the default grid, and a fused multiply-add
changes the chosen centre sample in 5 of the 117 frames (reproduced with
`math.fma`). pladdrr disables floating-point contraction on purpose
(`#pragma STDC FP_CONTRACT OFF` in `melder.h`), so it follows the non-fused
result. That the app is built with contraction is inferred from the simulation,
not from its build flags. Treat differences of this size on a frame grid that
hits exact sample boundaries as a platform artifact, not a pladdrr defect;
the 1e-05 tolerance above already covers it.

_Oracle: Praat 6.4.47 (November 7 2025) on Darwin (aarch64-apple-darwin23)._
