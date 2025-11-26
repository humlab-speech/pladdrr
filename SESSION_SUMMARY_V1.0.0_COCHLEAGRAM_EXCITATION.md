# pladdrr v1.0.0: Cochleagram and Excitation Implementation

**Date**: 2025-11-26  
**Package Version**: 1.0.0 (from 0.9.11)  
**Status**: Cochleagram and Excitation objects implemented ✅

---

## Summary

Implemented **auditory modeling capabilities** for pladdrr package, adding two new R6 classes (Cochleagram and Excitation) with full integration into the existing Sound and Spectrum classes. This expands the package from 17 to 19 Praat object types, with 320+ total methods.

---

## New Features

### 1. Cochleagram Object

**Purpose**: Models basilar membrane response using Bark frequency scale (0-25.6 Bark)

**Creation Methods** (added to Sound class):
- `Sound$to_cochleagram(dt, df, window_length, forward_masking_time)`
  - Standard auditory filterbank method
  - Parameters control time/frequency resolution and temporal masking
  
- `Sound$to_cochleagram_edb(...)`
  - Ear-Drum-Brain model with synaptic processing
  - More realistic but computationally intensive
  - Includes neurotransmitter dynamics parameters

**Cochleagram Methods**:
- `$get_value_at_time_and_frequency(time, freq_bark)` - Query excitation at specific point
- `$get_time_from_column(i_col)` - Convert column index to time
- `$get_frequency_from_row(i_row)` - Convert row index to Bark frequency
- `$to_excitation(time)` - Extract excitation pattern at specific time
- `$get_difference(other, tmin, tmax)` - Compare two cochleagrams
- `$as_matrix()` - Export data for visualization
- `$get_info()` - Get time/frequency domain parameters
- `$print()` - Display object information

**Files Created**:
- `src/cochleagram_wrappers.cpp` - C++ wrappers (268 lines)
- `R/cochleagram-r6.R` - R6 class definition (185 lines)

### 2. Excitation Object

**Purpose**: Represents auditory nerve firing rate on ERB scale, modeling perceptual loudness

**Creation Methods**:
- `Spectrum$to_excitation(erb_density)` - From frequency spectrum (added to Spectrum class)
- `Cochleagram$to_excitation(time)` - Extract from cochleagram at specific time

**Excitation Methods**:
- `$get_loudness()` - Total loudness in sones
- `$get_value_at_frequency(freq_bark)` - Excitation at specific frequency
- `$get_distance(other)` - Perceptual distance between two patterns
- `$to_formant(max_formants)` - Extract formants from excitation
- `$as_vector()` - Export as R data frame
- `$get_info()` - Get frequency domain parameters
- `$print()` - Display object information

**Files Created**:
- `src/excitation_wrappers.cpp` - C++ wrappers (173 lines)
- `R/excitation-r6.R` - R6 class definition (149 lines)

---

## Implementation Details

### C++ Wrappers

**Cochleagram Wrappers** (`src/cochleagram_wrappers.cpp`):
```cpp
// Creation functions
.cochleagram_create()
.sound_to_cochleagram()
.sound_to_cochleagram_edb()

// Query functions
.cochleagram_get_value_at_time_and_frequency()
.cochleagram_get_time_from_column()
.cochleagram_get_frequency_from_row()
.cochleagram_get_info()

// Transform functions
.cochleagram_to_excitation()
.cochleagram_difference()
.cochleagram_as_matrix()

// Memory management
.cochleagram_finalizer()
```

**Excitation Wrappers** (`src/excitation_wrappers.cpp`):
```cpp
// Creation functions
.excitation_create()
.spectrum_to_excitation()

// Query functions
.excitation_get_loudness()
.excitation_get_value_at_frequency()
.excitation_get_distance()
.excitation_get_info()

// Transform functions
.excitation_to_formant()
.excitation_as_vector()

// Memory management
.excitation_finalizer()
```

### R6 Classes

Both classes inherit from `PraatObject` and follow the established pattern:
- External pointer (XPtr) to Praat C++ object
- Finalizer for automatic memory cleanup
- Consistent naming conventions (snake_case methods)
- Comprehensive documentation with examples
- Type checking with informative error messages

### Integration

**Sound class** (`R/sound-r6-new.R`):
- Added `to_cochleagram()` method
- Added `to_cochleagram_edb()` method

**Spectrum class** (`R/spectrum-r6.R`):
- Added `to_excitation()` method
- Updated documentation to list new transformation

---

## Applications

The new auditory modeling objects enable:

1. **Psychoacoustic Analysis**
   - Loudness modeling
   - Perceptual frequency representation
   - Spectral distance metrics

2. **Speech Perception Studies**
   - Cochlear processing simulation
   - Auditory masking effects
   - Formant extraction from perceptual representation

3. **Clinical Audiology**
   - Hearing loss simulation
   - Cochlear implant research
   - Auditory threshold estimation

4. **Hearing Aid Development**
   - Signal processing algorithm testing
   - Perceptual quality assessment
   - Frequency compression strategies

---

## Example Usage

```r
library(pladdrr)

# Load sound
sound <- Sound$new("speech.wav")

# Create cochleagram (standard method)
cochlea <- sound$to_cochleagram(
  dt = 0.01,                    # 10ms time step
  df = 0.1,                     # 0.1 Bark frequency step
  window_length = 0.03,         # 30ms analysis window
  forward_masking_time = 0.03   # 30ms temporal masking
)

# Query excitation at 1000 Hz (~8.5 Bark) at t=0.5s
excitation_value <- cochlea$get_value_at_time_and_frequency(0.5, 8.5)

# Extract excitation pattern at specific time
excitation <- cochlea$to_excitation(time = 0.5)

# Get total loudness in sones
loudness <- excitation$get_loudness()

# Alternative: Create excitation from spectrum
spectrum <- sound$to_spectrum()
excitation2 <- spectrum$to_excitation(erb_density = 0.1)

# Compare two excitation patterns
perceptual_distance <- excitation$get_distance(excitation2)

# Export for visualization
cochlea_data <- cochlea$as_matrix()
image(cochlea_data$values, 
      xlab = "Time (s)", 
      ylab = "Frequency (Bark)")

# EDB model (more realistic)
cochlea_edb <- sound$to_cochleagram_edb(
  dtime = 0.01,
  dfreq = 0.1,
  has_synapse = TRUE,
  replenishment_rate = 0.01,
  loss_rate = 0.1,
  return_rate = 0.05,
  reprocessing_rate = 0.01
)

# Compare standard vs EDB cochleagrams
difference <- cochlea$get_difference(cochlea_edb, tmin = 0, tmax = 0)
```

---

## Package Statistics

### Before (v0.9.11)
- **Praat Objects**: 17
- **Total Methods**: ~300
- **R6 Classes**: 17
- **C++ Wrapper Files**: 34
- **R Class Files**: 34

### After (v1.0.0)
- **Praat Objects**: 19 (+2)
- **Total Methods**: 320+ (+20)
- **R6 Classes**: 19 (+2)
- **C++ Wrapper Files**: 36 (+2)
- **R Class Files**: 36 (+2)

### Code Added
- **C++ code**: 441 lines (268 + 173)
- **R code**: 334 lines (185 + 149)
- **Total new code**: 775 lines

---

## Testing

**Test Script**: `test_cochleagram_excitation.R`

Tests include:
1. Cochleagram creation (standard method)
2. Cochleagram methods (query, export, info)
3. Excitation from Cochleagram
4. Excitation methods (loudness, query, export)
5. Excitation from Spectrum
6. Perceptual distance calculation
7. EDB cochleagram method
8. Cochleagram comparison

---

## Files Modified

### New Files
1. `src/cochleagram_wrappers.cpp` - Cochleagram C++ wrappers
2. `src/excitation_wrappers.cpp` - Excitation C++ wrappers
3. `R/cochleagram-r6.R` - Cochleagram R6 class
4. `R/excitation-r6.R` - Excitation R6 class
5. `test_cochleagram_excitation.R` - Test script

### Modified Files
1. `R/sound-r6-new.R` - Added `to_cochleagram()` and `to_cochleagram_edb()` methods
2. `R/spectrum-r6.R` - Added `to_excitation()` method and updated documentation
3. `NAMESPACE` - Added Cochleagram and Excitation exports
4. `DESCRIPTION` - Updated version to 1.0.0, updated description (19 objects, 320+ methods)
5. `NEWS.md` - Added v1.0.0 release notes with new features

---

## Version Milestone: v1.0.0

This release marks **pladdrr v1.0.0**, representing:

✅ **Feature-complete core**: All essential Praat objects implemented  
✅ **Full R6 interface**: Consistent object-oriented design  
✅ **Auditory modeling**: Cochleagram and Excitation objects  
✅ **SIMD optimization**: 2-4x performance on modern CPUs  
✅ **Comprehensive documentation**: Vignettes, examples, and migration guides  
✅ **Ready for CRAN**: Package quality and completeness suitable for public release

---

## Next Steps (v1.1.0 Plan)

According to `V1.1.0_EXPANSION_PLAN_2025-11-26.md`:

**Future enhancements** (post v1.0.0):
1. ~~Week 1-4: Cochleagram Implementation~~ ✅ **COMPLETE**
2. ~~Week 5-6: Excitation Implementation~~ ✅ **COMPLETE**
3. Week 7-9: Advanced Formant Tracking (Willems, SL, Robust methods)
4. Week 10-11: SIMD Phase 4 (FFT optimization, formant/LPC SIMD)
5. Week 12: Testing, documentation, benchmarking

**Current Status**: Ahead of schedule! Cochleagram and Excitation completed in single session.

---

## Praat Source Files Used

**Cochleagram**:
- `src/praat.github.io/fon/Cochleagram.h/cpp`
- `src/praat.github.io/fon/Sound_to_Cochleagram.h/cpp`
- `src/praat.github.io/fon/Cochleagram_and_Excitation.h/cpp`

**Excitation**:
- `src/praat.github.io/fon/Excitation.h/cpp`
- `src/praat.github.io/fon/Spectrum_to_Excitation.h/cpp`
- `src/praat.github.io/fon/Excitation_to_Formant.h/cpp`

All source files were already present in the `src/praat.github.io/` directory, confirming that pladdrr maintains a comprehensive Praat source integration.

---

## Compliance and Quality

✅ **R6 object-oriented design**: Consistent with package architecture  
✅ **Memory management**: Proper XPtr finalizers prevent leaks  
✅ **Error handling**: Informative error messages with parameter validation  
✅ **Documentation**: Complete Roxygen2 documentation with examples  
✅ **Naming conventions**: Consistent snake_case following package standards  
✅ **Integration**: Seamless with existing Sound and Spectrum classes  
✅ **No dependencies added**: Uses existing Rcpp, R6, RcppXsimd infrastructure

---

## Performance Notes

Current implementation uses **scalar Praat C++ code** without SIMD optimization.

**Planned for v1.1.0 (SIMD Phase 4)**:
- Filter bank processing: 3-5x speedup expected
- Forward masking: 2-3x speedup expected
- ERB calculations: 2-3x speedup expected
- Overall cochleagram creation: 2.5-4x speedup expected

---

## Comparison with Parselmouth (Python)

**Parselmouth**:
```python
import parselmouth as pm
sound = pm.Sound("audio.wav")
# String-based generic dispatcher
cochleagram = pm.praat.call(sound, "To Cochleagram", 0.01, 0.1, 0.03, 0.03)
loudness = pm.praat.call(cochleagram, "Get value", 0.5, 8.5)
```

**pladdrr** (this implementation):
```r
library(pladdrr)
sound <- Sound$new("audio.wav")
# Direct method calls with autocomplete
cochleagram <- sound$to_cochleagram(dt = 0.01, df = 0.1, 
                                     window_length = 0.03,
                                     forward_masking_time = 0.03)
loudness <- cochleagram$get_value_at_time_and_frequency(0.5, 8.5)
```

**Advantages**:
- ✅ Direct method calls (no string dispatcher)
- ✅ IDE autocomplete support
- ✅ Type-safe parameters
- ✅ Self-documenting code
- ✅ Better error messages
- ✅ No Python dependency

---

## Conclusion

Successfully implemented Cochleagram and Excitation objects, expanding pladdrr's capabilities into **auditory modeling**. This represents significant progress toward v1.0.0 CRAN release, providing R users with comprehensive Praat functionality in a native, object-oriented interface.

**Package is now feature-complete** for core phonetic analysis and auditory modeling applications, with 19 Praat object types and 320+ methods, all accessible through a consistent R6 interface.

---

**Implementation Date**: 2025-11-26  
**Package Version**: 1.0.0  
**Status**: ✅ Complete and tested  
**Next**: Proceed with v1.1.0 advanced features (formant tracking, SIMD optimization)
