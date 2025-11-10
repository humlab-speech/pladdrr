# Object-Oriented Implementation Assessment & Roadmap

**Date**: 2025-11-10  
**Version**: 0.2.2  
**Status**: Implementation In Progress

## Executive Summary

The `speaker` package is being transformed into a comprehensive R interface to Praat's object-oriented codebase, following the design pattern of Python's Parselmouth. The package uses R6 classes wrapping Praat C++ objects via external pointers (XPtr), enabling zero-copy operations and a natural object-oriented API.

## Design Philosophy

### Praat's OOP Structure

Praat's codebase is fundamentally object-oriented with:
- **Base classes**: `Data`, `Sampled`, `Vector`, `Matrix`, etc.
- **Derived classes**: `Sound`, `Pitch`, `Formant`, `Spectrum`, etc.
- **Method pattern**: `ClassName_methodName(object, ...)`
- **Object lifecycle**: Creation → Analysis → Transformation → Export

### R6 Implementation Approach

We mirror Praat's OOP structure using:

1. **R6 Classes**: Each Praat object type maps to an R6 class
2. **External Pointers (XPtr)**: R6 objects hold lightweight references to C++ Praat objects
3. **Zero-Copy Operations**: Data stays in C++ memory; R only holds pointers
4. **Method Naming**: Consistent with Praat conventions for easy code translation
5. **Automatic Memory Management**: XPtr finalizers handle C++ object cleanup

### Naming Conventions for Praat Code Translation

To enable easy translation from Praat scripts to R code:

#### Object Methods
- **Praat**: `Sound_methodName(sound, ...)`  
- **R**: `sound$method_name(...)`

Examples:
```r
# Praat: pitch = To Pitch... 0.0 75.0 600.0
# R:     pitch <- sound$to_pitch(time_step = 0.0, pitch_floor = 75.0, pitch_ceiling = 600.0)

# Praat: mean_f0 = Get mean... 0.0 0.0 Hertz
# R:     mean_f0 <- pitch$get_mean(from_time = 0.0, to_time = 0.0, unit = "Hertz")

# Praat: formant = To Formant (burg)... 0.0 5.0 5500.0 0.025 50.0
# R:     formant <- sound$to_formant_burg(time_step = 0.0, max_formants = 5.0, 
#                                         max_frequency = 5500.0, window_length = 0.025, 
#                                         pre_emphasis = 50.0)
```

## Current Implementation Status

### ✅ Fully Implemented Objects

#### 1. Sound (Priority: CRITICAL)
**Status**: ~90% Complete  
**File**: `R/sound-r6-new.R`, `src/sound_wrappers.cpp`  
**Methods Implemented**: ~50

**Categories**:
- **Creation**: `new(path)`, `from_values()`, `from_matrix()`, `create_tone()`
- **Query**: `get_duration()`, `get_sampling_frequency()`, `get_number_of_samples()`, `get_number_of_channels()`, `get_value_at_time()`, `get_rms()`, `get_energy()`, `get_power()`, `get_intensity_db()`
- **Transformation**: `to_pitch()`, `to_formant_burg()`, `to_intensity()`, `to_harmonicity_cc()`, `to_spectrum()`, `to_spectrogram()`
- **Modification**: `resample()`, `scale_intensity()`, `extract_part()`
- **Export**: `as_data_frame()`, `as_matrix()`, `save()`

**Integration**: Uses `av` package (humlab-speech fork) for universal media loading (MP3, WAV, FLAC, OGG, etc.)

#### 2. Pitch (Priority: CRITICAL)
**Status**: 100% Complete  
**File**: `R/pitch-r6.R`, `src/pitch_wrappers.cpp`  
**Methods Implemented**: ~30

**Categories**:
- **Query**: `get_value_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`, `get_quantile()`
- **Frame queries**: `count_voiced_frames()`, `get_frame_number_from_time()`
- **Export**: `as_data_frame()`, `as_matrix()`

#### 3. Formant (Priority: CRITICAL)
**Status**: 100% Complete  
**File**: `R/formant-r6.R`, `src/formant_wrappers.cpp`  
**Methods Implemented**: ~20

**Categories**:
- **Query**: `get_value_at_time()`, `get_bandwidth_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`
- **Formant tracking**: Access to all formants (F1-F5+)
- **Export**: `as_data_frame()`, `as_matrix()`

#### 4. Intensity (Priority: CRITICAL)
**Status**: 100% Complete  
**File**: `R/intensity-r6.R`, `src/intensity_wrappers.cpp`  
**Methods Implemented**: ~15

**Categories**:
- **Query**: `get_value_at_time()`, `get_mean()`, `get_minimum()`, `get_maximum()`, `get_standard_deviation()`, `get_quantile()`
- **Export**: `as_data_frame()`, `as_matrix()`

#### 5. Harmonicity (Priority: HIGH)
**Status**: 100% Complete  
**File**: `R/harmonicity.R`, `src/harmonicity_wrappers.cpp`  
**Methods Implemented**: ~15

**Categories**:
- **Query**: HNR (Harmonics-to-Noise Ratio) queries, statistical methods
- **Export**: Data frame and matrix export

#### 6. Spectrum (Priority: HIGH)
**Status**: 80% Complete  
**File**: `R/spectrum-r6.R`, `src/spectrum_wrappers.cpp`  
**Methods Implemented**: ~10

**Categories**:
- **Query**: Power spectrum queries, frequency domain analysis
- **Export**: Data frame export

#### 7. PointProcess (Priority: HIGH)
**Status**: 90% Complete  
**File**: `R/pointprocess-r6.R`, `src/pointprocess_wrappers.cpp`  
**Methods Implemented**: ~25

**Categories**:
- **Query**: Point queries, interval statistics
- **Voice quality**: Jitter and shimmer calculations (with Sound object)
- **Export**: Data frame export

### 🚧 Partially Implemented Objects

#### 8. TextGrid (Priority: HIGH)
**Status**: Structure Defined, Implementation Disabled  
**File**: `R/textgrid-r6.R.disabled`  
**Reason**: Complex nested structure requiring careful design

**Needed**:
- Tier management (get/add/remove tiers)
- Interval/Point manipulation within tiers
- Time-based queries
- Export to standard formats

### ❌ Not Yet Implemented (High Priority)

#### 9. Spectrogram (Priority: HIGH)
**Praat Source**: `inst/praat-src/fon/Spectrogram.cpp`  
**Methods Needed**: ~15

**Categories**:
- **Creation**: `Sound$to_spectrogram()`
- **Query**: `get_power_at()`, time-frequency analysis
- **Transformation**: `to_spectrum()`, `to_ltas()`

#### 10. Manipulation (Priority: CRITICAL for synthesis)
**Praat Source**: `inst/praat-src/fon/Manipulation.cpp`  
**Methods Needed**: ~12

**Categories**:
- **Creation**: `Sound$to_manipulation()`
- **Query**: `get_pitch_tier()`, `get_duration_tier()`
- **Modification**: PSOLA-based pitch/duration modification
- **Synthesis**: `get_resynthesis()`

**Importance**: Essential for speech synthesis and prosody modification

#### 11. PitchTier (Priority: HIGH)
**Praat Source**: `inst/praat-src/fon/PitchTier.cpp`  
**Methods Needed**: ~12

**Categories**:
- **Point manipulation**: `add_point()`, `remove_point()`, `remove_points_between()`
- **Modification**: `multiply()`, `shift_frequencies()`, `stylize()`

#### 12. LPC (Priority: MEDIUM)
**Praat Source**: `inst/praat-src/LPC/LPC.cpp`  
**Methods Needed**: ~10

**Categories**:
- **Creation**: `Sound$to_lpc_autocorrelation()`, `Sound$to_lpc_covariance()`
- **Transformation**: `to_formant()`, `to_spectrum()`

#### 13. Ltas (Long-Term Average Spectrum) (Priority: MEDIUM)
**Praat Source**: `inst/praat-src/fon/Ltas.cpp`  
**Methods Needed**: ~12

**Categories**:
- **Creation**: `Sound$to_ltas()`, `Spectrogram$to_ltas()`
- **Query**: Frequency bin queries, statistical methods

### 🔮 Future Extensions (Lower Priority)

#### 14. IntensityTier, DurationTier, FormantGrid
For advanced manipulation workflows

#### 15. Matrix (Base class)
Generic 2D data manipulation

#### 16. Cochleagram, Excitation, MFCC
Advanced auditory models

## Architecture Decisions

### 1. Media Loading Strategy (COMPLETED)
**Decision**: Use `av` package (humlab-speech fork) for audio I/O  
**Rationale**:
- Universal format support (MP3, WAV, FLAC, OGG, AAC, etc.)
- Leverages FFmpeg
- Avoids reinventing audio codec support
- Already used by related packages

**Implementation**: `Sound$new(path)` uses `av::read_audio_fft()` internally

### 2. Praat Script Interpreter (DEFERRED)
**Decision**: Defer full Praat script interpretation  
**Rationale**:
- Complex to implement
- R API is primary interface
- Users can translate scripts using naming conventions

**Future Extension**: Could add `praat_script()` function to execute Praat scripts directly

**Documentation Note**: Users cannot currently run unmodified Praat scripts; they must translate to R using the object methods.

### 3. Picture/Graphics Support (DEFERRED)
**Decision**: Defer Praat Picture window functionality  
**Rationale**:
- R has superior graphics (ggplot2, etc.)
- Praat graphics are X11/UI-dependent
- Core analysis > visualization

**Future Extension**: Could expose drawing primitives for specialized Praat plots

**Documentation Note**: Praat's Picture window functionality is not available; use R graphics packages instead.

### 4. C++ Standard (RESOLVED)
**Decision**: Require C++17  
**Rationale**:
- Praat source uses modern C++17 features
- R 4.0+ supports C++17
- Better compatibility with Praat codebase

**Implementation**: `SystemRequirements: C++17` in DESCRIPTION

## Implementation Roadmap

### Phase 1: Core Objects (COMPLETE ✅)
**Target**: v0.2.x  
**Status**: DONE

- [x] Sound object with av integration
- [x] Pitch analysis
- [x] Formant analysis  
- [x] Intensity analysis
- [x] Harmonicity analysis
- [x] PointProcess for voice quality
- [x] Spectrum basics

### Phase 2: Advanced Analysis (IN PROGRESS 🚧)
**Target**: v0.3.x  
**Status**: 40% Complete

- [x] Spectrum (80% done)
- [ ] Spectrogram
- [ ] Ltas
- [ ] LPC
- [ ] TextGrid (re-enable and complete)

### Phase 3: Synthesis & Manipulation (PLANNED 📋)
**Target**: v0.4.x

- [ ] Manipulation object
- [ ] PitchTier
- [ ] DurationTier
- [ ] IntensityTier
- [ ] FormantGrid
- [ ] Sound resynthesis

### Phase 4: Advanced Features (FUTURE 🔮)
**Target**: v0.5.x+

- [ ] Additional auditory models
- [ ] Matrix operations
- [ ] Optional Praat script interpreter
- [ ] Optional graphics primitives

## Testing Strategy

### Unit Tests
Each R6 class should have:
- Constructor tests
- Method validation tests
- Edge case handling
- Memory leak tests

### Integration Tests
- Multi-step workflows (Sound → Pitch → analysis)
- Format compatibility (av integration)
- Praat equivalence tests (compare to Praat output)

### Performance Benchmarks
- Zero-copy verification
- Large file handling
- Comparison with Parselmouth

## Examples from superassp Package

After core implementation, re-implement Python+Parselmouth examples from `/Users/frkkan96/Documents/src/superassp/inst/python` as R+speaker examples in `inst/examples/`.

This will:
- Validate feature parity
- Provide practical usage examples
- Demonstrate performance

## Documentation Plan

### Vignettes
1. **Introduction**: Basic Sound → Pitch → Formant workflow
2. **Advanced Analysis**: Multi-step analysis pipelines
3. **Voice Quality**: Jitter, shimmer, HNR
4. **Translation Guide**: Praat script → R code
5. **Performance**: Benchmarks and optimization tips

### Function Documentation
- All R6 methods documented with roxygen2
- Examples for each method
- Cross-references to Praat manual

## Dependencies

### Current
- R (>= 4.0.0) - For C++17 support
- Rcpp (>= 1.0.0) - C++ interface
- R6 (>= 2.5.0) - OOP framework
- av - Media I/O (humlab-speech fork)

### Future Considerations
- testthat (testing)
- ggplot2 (suggested for visualization examples)

## Success Metrics

1. **Feature Coverage**: >80% of commonly-used Praat functionality
2. **Performance**: ≥5x speedup vs. data-copying approaches for chained operations
3. **API Clarity**: Intuitive mapping from Praat commands to R methods
4. **Documentation**: Complete examples for all major workflows
5. **Testing**: >90% code coverage

## Conclusion

The `speaker` package is well on its way to becoming a comprehensive, performant, and user-friendly R interface to Praat's phonetic analysis capabilities. The object-oriented design mirrors Praat's structure while providing a natural R API, and the use of external pointers ensures efficient memory usage and fast execution.

The current implementation (v0.2.2) provides solid foundations with core objects (Sound, Pitch, Formant, Intensity, Harmonicity, PointProcess, Spectrum). The next phases will add advanced analysis objects (Spectrogram, Ltas, LPC) and synthesis capabilities (Manipulation, PitchTier, etc.).

---

**Next Steps**:
1. Complete Spectrum implementation
2. Implement Spectrogram
3. Re-enable and complete TextGrid
4. Begin Manipulation object for synthesis
5. Create comprehensive vignettes
6. Port superassp Python examples to R
