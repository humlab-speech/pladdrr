# Faithfulness Report (pladdrr vs Praat)

_Generated: 2026-07-12 19:06:44 CEST_

Each row is one Praat DSP routine. Praat output is the oracle; pladdrr
is checked against it at the documented tolerance. `pass` = within
tolerance, `fail` = drift (open an issue or document the rationale).

| Routine | Status | Praat | pladdrr | |Δ| | Tolerance |
|---------|--------|-------|---------|------|-----------|
| Sound$get_total_duration | pass | 1 | 1 | 0 | 0 |
| Sound$get_number_of_samples | pass | 44100 | 44100 | 0 | 0 |
| Sound -> Pitch (cc) -> mean F0 (Hz) | pass | 440.0102 | 440.0102 | 8.6402e-12 | 1e-04 |
| Sound -> Intensity -> mean (dB) | pass | 84.94803 | 84.94803 | 3.079001e-07 | 1e-06 |
| Sound -> Formant (burg) -> F1@0.5s (Hz) | pass | 420.6684 | 420.6684 | 5.360334e-11 | 0.001 |
