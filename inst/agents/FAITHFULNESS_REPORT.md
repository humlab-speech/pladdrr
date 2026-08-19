# Faithfulness Report (pladdrr vs Praat)

_Generated: 2026-08-19 17:10:44 CEST_

Each row is one Praat DSP routine. Praat output is the oracle; pladdrr
is checked against it at the documented tolerance. `pass` = within
tolerance, `fail` = drift (open an issue or document the rationale).

| Routine | Status | Praat | pladdrr | |Δ| | Tolerance |
|---------|--------|-------|---------|------|-----------|
| Sound$get_total_duration | pass | 1 | 1 | 0 | 0 |
| Sound$get_number_of_samples | pass | 44100 | 44100 | 0 | 0 |
| Sound -> Pitch (cc) -> mean F0 (Hz) | pass | 440.0102 | 440.0102 | 8.6402e-12 | 1e-04 |
| Sound -> Intensity -> mean (dB) | pass | 84.94803 | 84.94803 | 3.079001e-07 | 1e-06 |
| Sound -> Formant (burg) -> F1@0.5s (Hz) | pass | 420.6684 | 420.6684 | 5.633183e-11 | 0.001 |
| CPPS (calculate_cpps_ultra) | pass | 9.923184 | 9.920529 | 0.002654309 | 0.005 |
| Pitch (AC) -> mean F0 (Hz) | pass | 440.0102 | 440.0102 | 9.549694e-12 | 1e-04 |
| Pitch (SHS) -> mean F0 (Hz) | pass | 440.8181 | 440.8181 | 5.684342e-14 | 1e-04 |
| Intensity -> mean (energy-averaged, dB) | pass | 84.94803 | 84.94803 | 7.71907e-06 | 1e-05 |
| Formant (keepAll) -> F1@0.5s (Hz) | pass | 0 | 0 | 0 | 0.001 |
| Harmonicity (cc) -> mean (dB) | pass | 91.86342 | 91.8635 | 8.164053e-05 | 1e-04 |
| Spectrogram -> power at (0.5 s, 1000 Hz) | pass | 3.131686e-05 | 3.131686e-05 | 2.236167e-19 | 1e-09 |
| PointProcess (cc) -> jitter local | pass | 8.023673e-07 | 8.023673e-07 | 1.787663e-18 | 1e-09 |
| MFCC -> number of frames | pass | 195 | 195 | 0 | 0 |
| Sound$get_sampling_frequency | pass | 44100 | 44100 | 0 | 0 |
| Sound$get_number_of_channels | pass | 1 | 1 | 0 | 0 |
| Sound$get_mean | pass | 0 | 0 | 0 | 1e-12 |
| Sound$get_rms | pass | 0.3535251 | 0.3535251 | 0 | 1e-12 |

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
