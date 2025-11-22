# AVQI/DSI Implementation - Next Steps Summary
**Date**: 2025-11-22
**Package Version**: 0.9.1
**Status**: Infrastructure Complete, High-Level Functions Need Testing

## Current Status

### ✅ Completed (Infrastructure)
1. **Matrix Class Integration** - Complete CLAPACK numerical library integration
2. **Build System** - Package builds successfully
3. **Documentation** - Roxygen2 documentation generated
4. **Core Components**:
   - Voice Report (jitter/shimmer)
   - CPPS (Cepstral Peak Prominence)
   - HNR (Harmonicity)
   - Pitch extraction
   - Formant analysis
   - Intensity measurement
   - LTAS analysis
   - PowerCepstrogram

### ⚠️  Needs Testing
1. **compute_avqi()** - High-level AVQI calculation function (implemented but untested)
2. **compute_dsi()** - High-level DSI calculation function (implemented but untested)
3. **Plotting Functions** - ggplot2 visualizations (implemented but untested)
   - plot_avqi()
   - plot_dsi()
   - create_avqi_report_plot()
   - create_dsi_report_plot()

### ❌ Missing (Voice Activity Detection)
The only remaining missing functionality identified in the original plan:
- **Voice Activity Detection** - `sound_to_textgrid_silences()` 
- **TextGrid Interval Extraction** - `textgrid$extract_intervals_where()`

These are used for:
- AVQI: Extracting voiced segments from continuous speech
- Currently: AVQI works with pre-segmented vowels or full recordings

## Next Steps (Priority Order)

### Step 1: Test & Debug High-Level Functions (1-2 days)
1. Fix method name issues (e.g., `get_total_duration` vs `get_duration`)
2. Test `compute_avqi()` with:
   - Sustained vowel recordings
   - Continuous speech (if VAD not critical)
   - Both combined
3. Test `compute_dsi()` with voice recordings
4. Validate output against Praat AVQI301.praat and DSI201.praat scripts

### Step 2: Test & Debug Visualization Functions (1 day)
1. Test ggplot2 plotting functions
2. Verify visual output matches Praat style
3. Add examples to documentation

### Step 3: Implement Voice Activity Detection (2-3 days) - OPTIONAL
**Priority**: Medium (nice to have, not critical for basic functionality)

Only needed if:
- User wants automatic voiced segment extraction
- Processing continuous speech without manual segmentation

Can be deferred to later version if basic AVQI/DSI works.

### Step 4: Create Examples & Vignettes (2-3 days)
1. Create example audio files (synthetic + real)
2. Write vignette: "Computing AVQI in R"
3. Write vignette: "Computing DSI in R"  
4. Migration guide from Praat scripts

### Step 5: Validation & Testing (3-4 days)
1. Compare outputs with Praat for same audio files
2. Test with diverse voice samples:
   - Normal voices
   - Dysphonic voices
   - Different genders
   - Different recording conditions
3. Add unit tests
4. Add integration tests

## Implementation Files Status

### R Functions
- ✅ `R/avqi.R` - AVQI calculation (needs testing)
- ✅ `R/dsi.R` - DSI calculation (needs testing)
- ✅ `R/avqi_dsi_plots.R` - Visualization functions (needs testing)

### Documentation
- ✅ `man/avqi.Rd` - Generated
- ✅ `man/dsi.Rd` - Generated  
- ✅ `man/avqi_dsi_plots.Rd` - Generated

### C++ Wrappers
- ✅ `src/pointprocess_wrappers.cpp` - Voice report
- ✅ `src/powercepstrum_wrappers.cpp` - CPPS
- ❌ `src/vad_wrappers.cpp` - VAD (not implemented, optional)

## Success Criteria

### Minimum Viable Product (1 week)
- [ ] `compute_avqi()` works with vowel recordings
- [ ] `compute_dsi()` works with voice recordings  
- [ ] Basic plotting works
- [ ] 1-2 working examples

### Full Implementation (2-3 weeks)
- [ ] All AVQI types work (vowel, speech, combined)
- [ ] Voice Activity Detection implemented
- [ ] Complete plotting suite
- [ ] Comprehensive documentation
- [ ] Validation against Praat outputs
- [ ] Published vignettes

## Timeline Estimate

**Optimistic (MVP)**: 5-7 days
**Realistic (Full)**: 2-3 weeks  
**Conservative**: 4 weeks (with extensive validation)

## Blocking Issues

### Current Blockers
1. Method naming inconsistencies need fixing in AVQI/DSI code
   - Example: `get_total_duration()` should be `get_duration()`
2. Need to test if all component methods actually work

### Non-Blocking Issues
1. Voice Activity Detection can be implemented later
2. Can start with manual pre-segmentation workaround

## Recommendation

**Immediate Action**: Focus on Step 1 (Test & Debug) to:
1. Fix any method name issues in `compute_avqi()` and `compute_dsi()`  
2. Create simple test with synthetic audio
3. Verify core functionality works

**Defer to Later**:
1. Voice Activity Detection (can use manual segmentation for now)
2. Extensive validation (do after basic functionality confirmed)

This approach gets working AVQI/DSI functionality quickly, then polishes.

