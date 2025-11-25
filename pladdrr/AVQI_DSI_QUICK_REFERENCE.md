# AVQI & DSI Quick Reference Guide

## Current Implementation Status

### ✅ Already Implemented in speaker

- Sound I/O and basic processing
- Pitch analysis (To Pitch, Get mean/max/min)
- Formant analysis  
- Intensity analysis
- Harmonicity analysis (HNR)
- LTAS analysis (including slope calculations)
- PointProcess creation
- TextGrid manipulation
- Sound concatenation and extraction

### ❌ CRITICAL MISSING (Blocks AVQI/DSI)

| Feature | Priority | C++ Source | Estimated Effort |
|---------|----------|------------|------------------|
| **Voice Report** (jitter/shimmer) | HIGHEST | `fon/Sound_to_PointProcess.cpp` | 5 days |
| **CPPS** (Smoothed Cepstral Peak Prominence) | HIGH | `fon/PowerCepstrum.cpp` | 4 days |
| **Voice Activity Detection** | HIGH | `fon/Sound_to_TextGrid.cpp` | 3 days |
| **Bandstop Filter** | MEDIUM | `fon/Sound_filtering.cpp` | 1 day |
| **Power calculations** | MEDIUM | `fon/Sound.cpp` | 1 day |
| **PowerCepstrogram** | MEDIUM | `fon/PowerCepstrogram.cpp` | 2 days |

**Total Estimated Effort**: 16 days (3.2 weeks)

## Implementation Priority Order

1. **Voice Report** → Enables DSI (jitter ppq5) and AVQI (shimmer)
2. **CPPS** → Enables AVQI (critical acoustic measure)
3. **VAD** → Enables AVQI (voiced segment extraction)
4. **Other utilities** → Complete implementation

## AVQI Formula

```r
AVQI = 4.152 - (0.177 * CPPS) - (0.006 * HNR) - (0.037 * SL) + 
       (0.941 * SLdB) + (0.01 * Slope) + (0.093 * Tilt)
```

Where:
- **CPPS**: Smoothed Cepstral Peak Prominence (dB) → ❌ MISSING
- **HNR**: Harmonics-to-Noise Ratio (dB) → ✅ EXISTS
- **SL**: Shimmer Local (%) → ❌ MISSING (voice report)
- **SLdB**: Shimmer Local dB (dB) → ❌ MISSING (voice report)
- **Slope**: LTAS slope 0-1000 Hz vs 1000-5000 Hz → ✅ EXISTS  
- **Tilt**: LTAS tilt (H1-A3 approximation) → ✅ CAN COMPUTE

## DSI Formula

```r
DSI = 1.127 + (0.164 * MPT) - (0.038 * IL) + (0.0053 * FH) - (5.30 * PPQ)
```

Where:
- **MPT**: Maximum Phonation Time (s) → ✅ EXISTS (`sound$get_total_duration()`)
- **IL**: Softest Intensity of voiced speech (dB) → ✅ EXISTS (`intensity$get_minimum()`)
- **FH**: Highest F0 (Hz) → ✅ EXISTS (`pitch$get_maximum()`)
- **PPQ**: Jitter ppq5 (%) → ❌ MISSING (voice report)

## Code Templates

### Voice Report (C++ Wrapper Needed)

```cpp
// src/pointprocess_wrappers.cpp
// [[Rcpp::export]]
Rcpp::List praat_voice_report(
    SEXP sound_xptr,
    SEXP pitch_xptr,
    SEXP point_process_xptr,
    double time_min,
    double time_max,
    double pitch_floor,
    double pitch_ceiling,
    double max_period_factor,
    double max_amplitude_factor,
    double silence_threshold,
    double voicing_threshold
) {
    autoSound sound = unwrapSound(sound_xptr);
    autoPitch pitch = unwrapPitch(pitch_xptr);
    autoPointProcess pulses = unwrapPointProcess(point_process_xptr);
    
    // Call Praat function
    autostring32 report = Sound_Pitch_PointProcess_voiceReport(
        sound.get(), pitch.get(), pulses.get(),
        time_min, time_max, pitch_floor, pitch_ceiling,
        max_period_factor, max_amplitude_factor,
        silence_threshold, voicing_threshold
    );
    
    // Parse report string and extract values
    return Rcpp::List::create(
        Rcpp::Named("jitter_local") = /* extract */,
        Rcpp::Named("jitter_ppq5") = /* extract */,
        Rcpp::Named("shimmer_local") = /* extract */,
        Rcpp::Named("shimmer_local_db") = /* extract */,
        // ... etc
    );
}
```

### CPPS Calculation (C++ Wrapper Needed)

```cpp
// src/powercepstrum_wrappers.cpp
// [[Rcpp::export]]
double praat_powercepstrum_get_cpps(
    SEXP xptr,
    bool subtract_tilt,
    double time_averaging_window,
    double quefrency_averaging_window,
    double peak_search_pitch_floor,
    double peak_search_pitch_ceiling,
    const std::string& interpolation,
    double quefrency_step,
    double tolerance
) {
    autoPowerCepstrum cepstrum = unwrapPowerCepstrum(xptr);
    
    double cpps = PowerCepstrum_getCPPS(
        cepstrum.get(),
        subtract_tilt,
        time_averaging_window,
        quefrency_averaging_window,
        1.0 / peak_search_pitch_ceiling,  // Convert to quefrency
        1.0 / peak_search_pitch_floor,
        interpolation == "parabolic" ? 1 : 0,
        quefrency_step,
        tolerance
    );
    
    return cpps;
}
```

### R Interface

```r
# R/pointprocess-r6.R
voice_report = function(sound, pitch, 
                       time_range = c(0, 0),
                       pitch_floor = 75,
                       pitch_ceiling = 600,
                       max_period_factor = 1.3,
                       max_amplitude_factor = 1.6,
                       silence_threshold = 0.03,
                       voicing_threshold = 0.45) {
  praat_voice_report(
    sound$.xptr, pitch$.xptr, self$.xptr,
    time_range[1], time_range[2],
    pitch_floor, pitch_ceiling,
    max_period_factor, max_amplitude_factor,
    silence_threshold, voicing_threshold
  )
}

# R/powercepstrum-r6.R  
get_cpps = function(subtract_tilt = TRUE,
                   time_averaging_window = 0.001,
                   quefrency_averaging_window = 0.0005,
                   peak_search_floor = 60,
                   peak_search_ceiling = 333.3,
                   interpolation = "parabolic",
                   quefrency_step = 0.0001,
                   tolerance = 0.05) {
  praat_powercepstrum_get_cpps(
    self$.xptr,
    subtract_tilt,
    time_averaging_window,
    quefrency_averaging_window,
    peak_search_floor,
    peak_search_ceiling,
    interpolation,
    quefrency_step,
    tolerance
  )
}
```

## Testing Checklist

- [ ] Voice report matches Praat output (all jitter/shimmer values)
- [ ] CPPS matches Praat PowerCepstrum CPPS
- [ ] VAD produces identical voiced segments to Praat
- [ ] AVQI score within ±0.1 of Praat script output
- [ ] DSI score within ±0.1 of Praat script output
- [ ] All ggplot2 visualizations render correctly
- [ ] R Markdown reports generate successfully
- [ ] Package passes R CMD check with no warnings

## File Organization

```
R/
  avqi.R                 # compute_avqi() function
  dsi.R                  # compute_dsi() function  
  plot-avqi.R            # plot.avqi(), autoplot.avqi()
  plot-dsi.R             # plot.dsi(), autoplot.dsi()
  vad.R                  # Voice activity detection R interface
  voice-quality.R        # Shared utilities

src/
  vad_wrappers.cpp       # NEW: Voice activity detection wrappers
  pointprocess_wrappers.cpp  # EXTEND: Add voice_report
  powercepstrum_wrappers.cpp # EXTEND: Add get_cpps, smoothing
  sound_wrappers.cpp     # EXTEND: Add filter_stop_band, get_power

inst/
  extdata/
    test_cs.wav          # NEW: Test continuous speech
    test_sv.wav          # NEW: Test sustained vowel
    test_*.wav           # NEW: DSI test files
  rmarkdown/
    templates/
      avqi_report/       # NEW: AVQI R Markdown template
      dsi_report/        # NEW: DSI R Markdown template

vignettes/
  avqi.Rmd               # NEW: AVQI tutorial
  dsi.Rmd                # NEW: DSI tutorial
  voice-quality-indices.Rmd  # NEW: Overview

tests/
  testthat/
    test-avqi.R          # NEW: AVQI tests
    test-dsi.R           # NEW: DSI tests
    test-voice-report.R  # NEW: Voice report tests
    test-cpps.R          # NEW: CPPS tests
```

## Next Actions

1. **Start with Voice Report** - Most critical, enables both indices
2. **Implement CPPS** - Second most critical for AVQI
3. **Add VAD** - Required for AVQI voiced segment extraction
4. **Build AVQI function** - Combine all pieces
5. **Build DSI function** - Simpler, builds on voice report
6. **Create visualizations** - ggplot2 implementations
7. **Write documentation** - Vignettes and examples
8. **Testing** - Validate against Praat/superassp

## Timeline Estimate

- **Week 1-2**: Critical missing functionality (voice report, CPPS, VAD)
- **Week 3**: AVQI implementation + plots
- **Week 4**: DSI implementation + plots  
- **Week 5**: Documentation, testing, examples

**Total**: 5 weeks to production-ready implementation
