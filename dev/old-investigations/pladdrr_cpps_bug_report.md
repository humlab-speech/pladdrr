# pladdrr CPPS Calculation Bug Report

## Summary
pladdrr's `get_cpps()` method systematically underestimates CPPS by ~1.10-1.23 dB compared to Praat reference values when using identical parameters.

## Minimal Reproducible Example

### Test File
- File: `/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav`
- Duration: 7.664s
- Sample rate: 44100 Hz
- Content: Voiced segments extracted from continuous speech + sustained vowel

### R Code (pladdrr 1.2.5)
```r
library(pladdrr)

# Load test signal
sound <- Sound$new("/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav")

# Calculate CPPS with exact Praat parameters
cepstrogram <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  max_frequency = 5000,
  pre_emphasis_from = 50
)

cpps <- cepstrogram$get_cpps(
  subtract_trend_before_smoothing = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  peak_search_pitch_range_start = 60,
  peak_search_pitch_range_end = 330,
  tolerance = 0.05,
  interpolation = "parabolic",
  qstartFit = 0.001,
  qendFit = 0,
  lineType = "straight",
  fitMethod = "robust"
)

print(cpps)  # Returns: 9.94 dB
```

### Praat Reference (6.4.47)
```praat
sound = Read from file: "/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav"
cepstrogram = To PowerCepstrogram: 60, 0.002, 5000, 50
cpps = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05, "Parabolic", 0.001, 0, "Straight", "Robust"
writeInfoLine: cpps
# Outputs: 11.17 dB
```

### Python/Parselmouth Reference
```python
import parselmouth
sound = parselmouth.Sound("/tmp/avqi_intermediate_signals/praat/06_avqi_concatenated.wav")
cepstrogram = sound.to_powercepstrogram(60, 0.002, 5000, 50)
cpps = cepstrogram.get_cpps(False, 0.01, 0.001, 60, 330, 0.05, 
                            "parabolic", 0.001, 0, "Straight", "Robust")
print(cpps)  # Outputs: 12.25 dB
```

## Results Summary

| Implementation | CPPS (dB) | Error vs Praat |
|----------------|-----------|----------------|
| Praat 6.4.47   | 11.17     | Reference      |
| Python/Parselmouth | 12.25 | +1.08 dB      |
| R/pladdrr 1.2.5 | 9.94     | **-1.23 dB**  |

## Impact

This bug affects AVQI (Acoustic Voice Quality Index) v3.01 calculation:
- AVQI formula includes term: `-0.177 * CPPS * 2.8902 = -0.512 * CPPS`
- 1.23 dB CPPS underestimation causes **0.63 AVQI points error**
- Makes AVQI v3.01 R implementation unreliable (0.36 total error, 0.63 from CPPS alone)

## Investigation Done

Verified CPPS error persists across:
- ✅ Different `pre_emphasis_from` values (0, 50)
- ✅ Named vs positional parameters
- ✅ Different interpolation methods
- ✅ All parameter combinations matching Praat exactly

**Conclusion**: Systematic bias in pladdrr's C-level CPPS implementation, not configuration issue.

## Expected Behavior

pladdrr CPPS should match Praat within ±0.1 dB (accounting for minor numerical differences), as Parselmouth does (+1.08 dB difference is known Parselmouth characteristic).

## Environment

- **R**: 4.4.2
- **pladdrr**: 1.2.5
- **Platform**: macOS (darwin)
- **Praat reference**: 6.4.47 (Nov 2025)

## Test Files

Test signal and validation scripts available at:
https://github.com/frkkan96/plabench (reference in issue discussion)

## Request

Can you investigate the CPPS calculation in pladdrr's C binding to Praat? The systematic -1.23 dB bias suggests a potential issue with:
- Peak detection algorithm
- Quefrency-to-frequency conversion
- Trend line fitting
- dB scaling/normalization

This is blocking production use of AVQI v3.01 in R/pladdrr.
