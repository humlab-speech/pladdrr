# POC Implementation Plan: Rcpp Modules for Sound Class

**Goal**: Implement Sound class using Rcpp Modules to evaluate code reduction & maintainability vs current manual wrapper approach.

**Duration**: 1 week (5 working days)

**Baseline**: Sound class current implementation
- C++ wrappers: 48 exported functions, 1,479 lines
- R6 class: 59 methods, 1,254 lines
- **Total: 2,733 lines**

---

## Day 1: Setup & Basic Structure (Morning)

### Tasks
1. Create `src/sound_module_poc.cpp` with Rcpp Module
2. Implement 5 core methods:
   - `new()` constructor from file
   - `get_duration()`
   - `get_sampling_frequency()`
   - `get_number_of_samples()`
   - `get_number_of_channels()`
3. Build and test basic functionality

### Expected Lines of Code
- C++ module: ~150 lines (vs ~150 lines in current wrappers for same 5 methods)
- R wrapper: ~30 lines (vs ~200 lines current R6 for same 5 methods)
- **Total: ~180 lines** (vs ~350 lines current)

### Success Metrics
- POC builds successfully
- Basic queries work correctly
- Memory management verified (no leaks)

---

## Day 1: Extend POC (Afternoon)

### Tasks
4. Add 10 more query methods:
   - `get_value_at_time()`
   - `get_rms()`
   - `get_energy()`
   - `get_power()`
   - `get_intensity_db()`
   - `get_start_time()`, `get_end_time()`
   - `get_sampling_period()`
   - `get_time_from_index()`
   - `get_index_from_time()`

5. Add 3 transformation methods:
   - `to_pitch()`
   - `to_intensity()`
   - `to_spectrum()`

### Expected Lines of Code
- C++ additions: ~200 lines (vs ~400 lines current wrappers)
- R wrapper: minimal (Rcpp Modules auto-exposes methods)
- **Total POC: ~380 lines** (vs ~750 lines current for 18 methods)

---

## Day 2: Complex Methods & Return Types

### Tasks
6. Implement methods returning other Praat objects:
   - `to_formant_burg()` → returns Formant XPtr
   - `to_harmonicity_cc()` → returns Harmonicity XPtr
   - `to_spectrogram()` → returns Spectrogram XPtr

7. Implement methods with complex parameters:
   - `to_pitch_ac()` (11 parameters)
   - `to_pitch_cc()` (11 parameters)
   - `extract_part()` (6 parameters)

8. Test object chaining:
   ```r
   pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
   ```

### Expected Lines of Code
- C++ additions: ~150 lines (vs ~300 lines current)
- **Total POC: ~530 lines** (vs ~1,050 lines current for 24 methods)

---

## Day 3: Export & I/O Methods

### Tasks
9. Implement export methods:
   - `as_data_frame()`
   - `as_matrix()`
   - `save(path, format)`

10. Implement Sound creation methods:
   - Static `from_values(matrix, sr)`
   - Static `from_matrix(matrix, sr)`
   - Static `create_tone(duration, sr, freq, ...)`

11. Implement filtering & modification:
   - `filter_pass_hann_band()`
   - `filter_stop_hann_band()`
   - `resample()`
   - `convert_to_mono()`

### Expected Lines of Code
- C++ additions: ~250 lines (vs ~500 lines current)
- **Total POC: ~780 lines** (vs ~1,550 lines current for 35 methods)

---

## Day 4: Advanced Methods & Edge Cases

### Tasks
12. Implement remaining transformation methods:
   - `to_ltas()`
   - `to_textgrid_silences()` (complex: creates TextGrid)
   - Two-object commands:
     - `to_pointprocess_cc(pitch)` (Sound + Pitch → PointProcess)
     - `to_pointprocess_peaks(pitch)` (Sound + Pitch → PointProcess)

13. Implement remaining modification methods:
   - `scale_intensity()`
   - `scale_peak()`
   - `pre_emphasize()`
   - `de_emphasize()`

14. Implement extraction methods:
   - `extract_channel()`
   - `extract_part()`

15. Test error handling & edge cases

### Expected Lines of Code
- C++ additions: ~200 lines (vs ~400 lines current)
- **Total POC: ~980 lines** (vs ~1,950 lines current for 48 methods)

---

## Day 5: Benchmarking & Documentation

### Tasks
16. Performance benchmarking:
   - Load large file (100MB+ WAV)
   - Extract pitch 1,000 times
   - Measure memory usage
   - Compare POC vs current implementation

17. Code metrics comparison:
   - Lines of code (LOC)
   - Cyclomatic complexity
   - Compilation time
   - Binary size

18. Create comparison document:
   - Code reduction percentage
   - Maintainability assessment
   - Performance impact
   - Migration effort estimate

19. Make Go/No-Go decision

---

## Expected Outcome Projections

### Code Reduction (Estimated)

| Metric | Current | POC (Estimated) | Reduction |
|--------|---------|-----------------|-----------|
| C++ wrapper lines | 1,479 | ~980 | **34%** |
| R6 wrapper lines | 1,254 | ~50 | **96%** |
| **Total lines** | **2,733** | **~1,030** | **62%** |
| Functions/methods | 48 + 59 = 107 | ~50 | 53% |

### Parselmouth Comparison

Parselmouth Sound class: ~175 lines (pybind11)  
POC estimate: ~980 lines (Rcpp Modules)  
Gap: 5.6x (better than current 15.6x!)

**Why gap remains**:
- R type conversions more verbose than Python
- Error handling (Rcpp vs pybind11 has more boilerplate)
- Documentation comments (Parselmouth uses separate docs)

### Success Criteria

**GO Decision** if:
- ✅ Code reduction ≥ 50%
- ✅ No performance regression (within 5%)
- ✅ Compilation time ≤ current
- ✅ Memory usage unchanged
- ✅ API remains identical (no breaking changes)

**NO-GO Decision** if:
- ❌ Code reduction < 30%
- ❌ Performance regression > 10%
- ❌ Compilation problems (platform-specific issues)
- ❌ Memory leaks or instability
- ❌ Requires API breaking changes

---

## Implementation Notes

### Rcpp Modules Pattern

```cpp
// src/sound_module_poc.cpp
#include <Rcpp.h>
#include "fon/Sound.h"
#include "praat_xptr_utils.h"

using namespace Rcpp;

class SoundWrapper {
private:
    Rcpp::XPtr<structSound> ptr_;
    
public:
    // Constructor from file
    SoundWrapper(std::string path) {
        // ... use existing sound_read_from_file_native code
        ptr_ = create_sound_xptr(path);
    }
    
    // Query methods (declarative!)
    double get_duration() { return ptr_->xmax - ptr_->xmin; }
    double get_sampling_frequency() { return 1.0 / ptr_->dx; }
    int get_number_of_samples() { return ptr_->nx; }
    int get_number_of_channels() { return ptr_->ny; }
    
    // Transformation (return XPtr)
    SEXP to_pitch(double time_step, double pitch_floor, double pitch_ceiling) {
        autoPitch pitch = Sound_to_Pitch(ptr_.get(), time_step, pitch_floor, pitch_ceiling);
        return create_xptr_from_auto<structPitch>(pitch);
    }
};

// Module registration (clean!)
RCPP_MODULE(sound_poc) {
    class_<SoundWrapper>("Sound")
        .constructor<std::string>("Create from file")
        .method("get_duration", &SoundWrapper::get_duration, "Duration in seconds")
        .method("get_sampling_frequency", &SoundWrapper::get_sampling_frequency, "Sampling rate in Hz")
        .method("to_pitch", &SoundWrapper::to_pitch, "Extract pitch contour")
        ;
}
```

### R Usage (unchanged!)

```r
# User code remains identical
sound <- Sound$new("audio.wav")
dur <- sound$get_duration()
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
```

---

## Risk Mitigation

### Risk 1: Rcpp Modules Limited Documentation
**Mitigation**: Use Parselmouth as reference, leverage existing Rcpp community

### Risk 2: Performance Overhead
**Mitigation**: Benchmark early (Day 5), compare to current optimized code

### Risk 3: Memory Management Complexity
**Mitigation**: Reuse proven XPtr patterns from current implementation

### Risk 4: Breaking API Changes
**Mitigation**: Keep API identical, only change implementation internals

---

## Next Steps After POC

### If GO Decision:
1. Complete Sound module implementation (remaining 10 methods)
2. Migrate Pitch class (similar complexity to Sound)
3. Create migration guide for remaining 16 objects
4. Estimate full migration: **3-4 weeks** for all 18 objects
5. Schedule phased rollout (1-2 objects per week)

### If NO-GO Decision:
1. Pursue **Incremental Improvements** instead:
   - Consolidate error handling macros
   - Template-based wrapper generation
   - Reduce R6 boilerplate
2. Document why Rcpp Modules didn't meet criteria
3. Archive POC for future reference

---

## Timeline Summary

| Day | Focus | Deliverable |
|-----|-------|-------------|
| 1 (AM) | Basic setup | 5 methods working |
| 1 (PM) | Query methods | 18 methods working |
| 2 | Complex transformations | 24 methods working |
| 3 | Export & I/O | 35 methods working |
| 4 | Advanced methods | 48 methods complete |
| 5 | Benchmarking | Decision document |

**Total**: 5 days, 48 methods, ~1,030 lines (vs 2,733 current)

---

**Document Created**: 2024-12-14  
**Author**: OpenCode (Claude)  
**Status**: READY TO BEGIN
