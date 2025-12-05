# Quick Reference: Cepstral Analysis in pladdrr

**Package:** pladdrr v1.0.9+  
**Status:** ✅ Production Ready (with 2 known limitations)

---

## What Works ✅

### PowerCepstrogram (CPPS for AVQI)
```r
# Create PowerCepstrogram
sound <- Sound$create_tone(1.0, 44100, 440, 0.2)
pcep <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,
  pre_emphasis_frequency = 50
)

# Get CPPS (Smoothed Cepstral Peak Prominence)
cpps <- pcep$get_cpps()
cat("CPPS:", cpps, "dB\n")
```

### PowerCepstrum Analysis
```r
# Create PowerCepstrum
spectrum <- sound$to_spectrum()
cep <- spectrum$to_powercepstrum()

# Hillenbrand CPP
cpp_hill <- cep$get_peak_prominence_hillenbrand(75, 300)
cat("CPP:", cpp_hill$prominence, "dB at", cpp_hill$quefrency, "s\n")

# Trend line analysis
trend <- cep$fit_trend_line(
  qmin = 0.001,
  qmax = 0.05,
  trend_type = "exponential decay"
)
cat("Slope:", trend$slope, "Intercept:", trend$intercept, "\n")

# Detrend
detrended <- cep$subtract_trend(0.001, 0.05)

# Convert back to spectrum
spec <- cep$to_spectrum(random_phases = FALSE)
```

### Complex Cepstrum
```r
# Create cepstrum (preserves phase)
cep <- sound$to_cepstrum()

# Bandwidth-weighted variant
cep_bw <- sound$to_cepstrum_bw()

# Hillenbrand variant
spec <- sound$to_spectrum()
cep_hill <- spec$to_cepstrum_hillenbrand()
```

---

## What Doesn't Work ⚠️

### PowerCepstrum RNR (Segfault)
```r
# DON'T USE - causes crash
# rnr <- cep$get_rnr(75, 300, 0.05)  # ❌ Segfault
```

**Workaround:** Use other voice quality metrics (HNR, CPP, shimmer, jitter)

### Cepstrum Round-Trip (Error)
```r
# DON'T USE - causes error
# cep <- sound$to_cepstrum()
# snd <- cep$to_sound()  # ❌ "invalid file argument"
```

**Workaround:** Use PowerCepstrum if you need conversions

---

## Common Workflows

### AVQI Component: CPPS
```r
# Standard AVQI CPPS calculation
sound <- Sound$new("voice.wav")
pcep <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,
  pre_emphasis_frequency = 50
)

cpps <- pcep$get_cpps(
  subtract_tilt = TRUE,
  time_averaging_window = 0.001,
  quefrency_averaging_window = 0.05,
  pitch_floor = 60,
  pitch_ceiling = 330
)

cat("CPPS for AVQI:", round(cpps, 2), "dB\n")
```

### Compare CPP Algorithms
```r
sound <- Sound$new("voice.wav")
spectrum <- sound$to_spectrum()
cep <- spectrum$to_powercepstrum()

# Standard
cpp_std <- cep$get_peak_prominence(
  qmin = 0.001,
  qmax = 0.05,
  fit_method = "exponential decay"
)

# Hillenbrand
cpp_hill <- cep$get_peak_prominence_hillenbrand(75, 300)

cat("Standard CPP:", round(cpp_std, 2), "dB\n")
cat("Hillenbrand CPP:", round(cpp_hill$prominence, 2), "dB\n")
```

### Spectral Tilt Analysis
```r
spectrum <- sound$to_spectrum()
cep <- spectrum$to_powercepstrum()

# Fit trend line
trend <- cep$fit_trend_line(
  qmin = 0.001,
  qmax = 0.05,
  trend_type = "straight",
  fit_method = "least squares"
)

cat("Spectral tilt (slope):", round(trend$slope, 2), "dB/quefrency\n")

# Get value at specific quefrency
value_at_10ms <- cep$get_trend_line_value(
  quefrency = 0.01,
  qstart_fit = 0.001,
  qend_fit = 0.05
)
```

---

## Parameter Validation

PowerCepstrogram creation validates:
- ✅ Sound duration ≥ 3/pitch_floor seconds
- ✅ maximum_frequency < Nyquist frequency
- ✅ All parameters > 0
- ✅ time_step ≤ duration

**Example errors:**
```r
# Too short
sound_short <- Sound$create_tone(0.01, 44100, 440, 0.2)
pcep <- sound_short$to_powercepstrogram(pitch_floor = 60)
# Error: Sound duration (0.010 s) is too short for pitch_floor 60.0 Hz.
#        Minimum duration: 0.050 s. Either use a longer sound or increase pitch_floor.

# Nyquist violation
sound_low <- Sound$create_tone(1.0, 10000, 440, 0.2)
pcep <- sound_low$to_powercepstrogram(maximum_frequency = 6000)
# Error: maximum_frequency (6000.0 Hz) must be less than Nyquist frequency (5000.0 Hz).
#        Sound sampling rate is 10000.0 Hz.
```

---

## Tips & Best Practices

### For Voice Analysis
- Use sounds ≥ 0.5 seconds for reliable CPPS
- Standard pitch range: 60-330 Hz for adult voice
- Time step: 0.002s (2ms) is standard
- Maximum frequency: 5000 Hz for voice, 8000 Hz for high-quality

### For Trend Analysis
- Use "exponential decay" for voice cepstra
- Fit range: 0.001-0.05s covers typical voice pitch
- "robust slow" fitting is most accurate but slowest

### For Comparisons
- Always use same parameters when comparing
- Hillenbrand method is standard in literature
- CPPS is more robust than CPP for pathological voice

---

## Function Reference

### Sound → PowerCepstrogram
`sound$to_powercepstrogram(pitch_floor, time_step, maximum_frequency, pre_emphasis_frequency)`

### Sound → Cepstrum
- `sound$to_cepstrum()` ✅
- `sound$to_cepstrum_bw()` ✅

### Spectrum → Cepstrum
- `spectrum$to_cepstrum()` ✅
- `spectrum$to_cepstrum_hillenbrand()` ✅

### Spectrum → PowerCepstrum
`spectrum$to_powercepstrum()` ✅

### PowerCepstrum Methods
- `get_peak_prominence()` ✅
- `get_peak_prominence_hillenbrand()` ✅
- `get_rnr()` ❌ Segfault
- `fit_trend_line()` ✅
- `get_trend_line_value()` ✅
- `subtract_trend()` ✅
- `subtract_trend_inplace()` ✅
- `to_spectrum()` ✅

### PowerCepstrogram Methods
- `get_cpps()` ✅
- `get_cpp_at_time()` ✅
- `get_mean_cpp()` ✅

### Cepstrum Methods
- `to_sound()` ❌ Error
- `to_spectrum()` ⚠️ Blocked by to_sound
- `to_powercepstrum()` ⚠️ Blocked by to_sound

---

## See Also

- `TEST_RESULTS_2025-12-05.md` - Full test results
- `SESSION_FINAL_SUMMARY.md` - Implementation summary
- `POWERCEPSTRUM_FUNCTIONALITY_EXPANSION.md` - Detailed documentation
- `?PowerCepstrum` - R documentation
- `?PowerCepstrogram` - R documentation

---

**Last Updated:** 2025-12-05  
**Package Version:** 1.0.9+
