# AVQI & DSI Implementation Summary

## Three Planning Documents Created

1. **AVQI_DSI_IMPLEMENTATION_PLAN.md** (Comprehensive, 28KB)
   - Complete implementation roadmap
   - All Praat operations catalogued
   - Missing functionality detailed
   - ggplot2 visualization specifications
   - Report generation architecture
   - 5-week implementation timeline

2. **AVQI_DSI_QUICK_REFERENCE.md** (Quick guide, 8KB)
   - Current implementation status
   - Priority order
   - Code templates (C++ and R)
   - Testing checklist
   - File organization
   - Timeline estimate

3. **PRAAT_TO_SPEAKER_AVQI_DSI.md** (Translation guide, 20KB)
   - Line-by-line Praat script → speaker mapping
   - AVQI section-by-section translation
   - DSI section-by-section translation
   - Exact code equivalents
   - Implementation requirements

## Executive Summary

### What AVQI & DSI Are

- **AVQI (Acoustic Voice Quality Index)**: Multi-parameter assessment of dysphonia severity combining sustained vowel and continuous speech
- **DSI (Dysphonia Severity Index)**: Clinical voice disorder index based on 4 weighted measures

### Current Status

✅ **74% of required functionality EXISTS** in speaker package:
- Sound I/O, filtering (partial), concatenation
- Pitch, Formant, Intensity, Harmonicity analysis
- LTAS with slope calculations
- PointProcess creation
- TextGrid manipulation

❌ **26% MISSING** - 7 critical functions block implementation:

| Function | Priority | Effort | Blocks |
|----------|----------|--------|--------|
| Voice Report (jitter/shimmer) | HIGHEST | 5 days | Both AVQI & DSI |
| CPPS (Cepstral Peak Prominence) | HIGH | 4 days | AVQI |
| Voice Activity Detection | HIGH | 3 days | AVQI |
| PowerCepstrogram | MEDIUM | 2 days | AVQI |
| Bandstop Filter | MEDIUM | 1 day | AVQI (minor) |
| Power calculations | MEDIUM | 1 day | AVQI (minor) |
| Formula interface | LOW | 1 day | DSI (calibration) |

**Total Missing**: 17 days (3.4 weeks)

### Implementation Timeline

**Week 1-2**: Critical missing functionality
- Voice Report implementation (enables DSI jitter, AVQI shimmer)
- CPPS implementation (enables AVQI cepstral measure)
- VAD implementation (enables AVQI voiced segment extraction)

**Week 3**: AVQI implementation
- Core `compute_avqi()` function
- ggplot2 visualizations (waveform, spectrogram+LTAS, cepstrogram)
- Testing against Praat reference values

**Week 4**: DSI implementation  
- Core `compute_dsi()` function
- ggplot2 visualizations (score bar, pitch/intensity contours)
- Testing against Praat reference values

**Week 5**: Documentation & polish
- Vignettes (AVQI, DSI, overview)
- Function documentation
- R Markdown report templates
- Test data and examples

**Total**: 5 weeks to production-ready

### Key Design Decisions

1. **No Praat Graphics**: Use ggplot2 exclusively for all visualizations
2. **R6 Object-Oriented**: Consistent with package architecture
3. **Report Generation**: R Markdown templates (HTML/PDF/DOCX)
4. **Testing**: Validate against superassp reference implementations

### Formulas

**AVQI**:
```r
AVQI = 4.152 - 0.177*CPPS - 0.006*HNR - 0.037*ShimmerLocal + 
       0.941*ShimmerLocalDB + 0.01*Slope + 0.093*Tilt
```

**DSI**:
```r
DSI = 1.127 + 0.164*MPT - 0.038*Imin + 0.0053*Fhigh - 5.30*JitterPPQ5
```

### Usage Preview

```r
library(speaker)

# AVQI
avqi_result <- compute_avqi(
  cs_files = c("speech1.wav", "speech2.wav"),
  sv_files = c("vowel1.wav", "vowel2.wav"),
  patient_name = "John Doe",
  generate_plots = TRUE
)
print(avqi_result)
plot(avqi_result)
generate_avqi_report(avqi_result, "report.html")

# DSI
dsi_result <- compute_dsi(
  mpt_files = "max_phonation.wav",
  im_files = c("soft1.wav", "soft2.wav"),
  fh_files = c("high1.wav", "high2.wav"),
  ppq_files = "sustained_vowel.wav",
  patient_name = "Jane Smith"
)
print(dsi_result)
plot(dsi_result)
generate_dsi_report(dsi_result, "report.pdf", format = "pdf")
```

### Success Metrics

- [ ] AVQI within ±5% of Praat reference
- [ ] DSI within ±5% of Praat reference
- [ ] All visualizations render correctly
- [ ] Reports generate successfully
- [ ] >90% test coverage
- [ ] R CMD check clean
- [ ] Documentation complete

### Dependencies to Add

```r
# DESCRIPTION
Imports:
  ggplot2 (>= 3.4.0),
  patchwork (>= 1.1.0),
  scales,
  viridisLite
Suggests:
  knitr,
  rmarkdown,
  testthat (>= 3.0.0)
```

### File Structure

```
speaker/
├── R/
│   ├── avqi.R                    # NEW
│   ├── dsi.R                     # NEW
│   ├── plot-avqi.R               # NEW
│   ├── plot-dsi.R                # NEW
│   └── vad.R                     # NEW
├── src/
│   ├── vad_wrappers.cpp          # NEW
│   ├── pointprocess_wrappers.cpp # EXTEND (add voice_report)
│   ├── powercepstrum_wrappers.cpp# EXTEND (add CPPS, PowerCepstrogram)
│   └── sound_wrappers.cpp        # EXTEND (add filters, power)
├── inst/
│   ├── extdata/                  # NEW test audio files
│   └── rmarkdown/templates/      # NEW report templates
├── vignettes/
│   ├── avqi.Rmd                  # NEW
│   ├── dsi.Rmd                   # NEW
│   └── voice-quality-indices.Rmd # NEW
└── tests/testthat/
    ├── test-avqi.R               # NEW
    ├── test-dsi.R                # NEW
    └── test-voice-report.R       # NEW
```

## Next Actions

1. Review planning documents
2. Confirm approach and priorities
3. Begin Phase 1: Voice Report implementation
4. Iterative development with testing

## References

- superassp Praat scripts: AVQI301.praat, DSI201.praat
- Praat C++ source: `fon/` directory
- speaker package architecture: OOP_ARCHITECTURE_COMPREHENSIVE_AMENDMENT_2025-11-12.md

---

**Planning Complete**: Ready for implementation start  
**Estimated Time to v1.0**: 5 weeks with AVQI/DSI fully functional
