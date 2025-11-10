# Object-Oriented Implementation Roadmap - Speaker Package

**Date:** 2025-11-10  
**Master Plan:** `specs/001-praat-r-access/OOP-ARCHITECTURE-AMENDMENT.md`  
**Status:** Active Implementation

## Executive Summary

The speaker package is being restructured to comprehensively mirror Praat's object-oriented architecture using R6 classes. This enables direct transcoding of Praat scripts to R and eliminates Python/Parselmouth dependencies.

## Implementation Status

### ✅ Phase 1A: Foundation Objects (COMPLETE)

| Object | Status | Methods | Notes |
|--------|--------|---------|-------|
| **PraatObject** | ✅ Complete | Base class infrastructure | XPtr memory management |
| **Sound** | ✅ ~80% Complete | 25/40 methods | Missing: filtering, resampling, concatenation |
| **Pitch** | ✅ ~70% Complete | 14/20 methods | Missing: interpolate, smooth, to_sound |
| **Intensity** | ✅ Complete | 12/12 methods | Full R6 implementation |
| **Harmonicity** | ✅ Complete | 10/10 methods | Full HNR analysis |
| **PointProcess** | ✅ Complete | 18/18 methods | Jitter/shimmer complete |
| **TextGrid** | ✅ ~90% Complete | 35/40 methods | Comprehensive tier management |

### 🔄 Phase 1B: Critical Migrations (IN PROGRESS)

| Object | Status | Priority | Effort |
|--------|--------|----------|--------|
| **Formant** | ⚠️ **S3 → R6 MIGRATION NEEDED** | 🔴 CRITICAL | 1 day |

**Current State:** Formant exists as S3 class with functional implementation  
**Required:** Convert to R6 to maintain architectural consistency  
**Impact:** High - formant analysis is core phonetics functionality

**Timeline:** Start immediately, complete within 1 day

### ❌ Phase 2: Manipulation System (NOT STARTED) - CRITICAL GAP

| Object | Status | Priority | Effort | Depends On |
|--------|--------|----------|--------|------------|
| **Manipulation** | ❌ Not implemented | 🔴 CRITICAL | 3 days | Sound, Pitch |
| **PitchTier** | ❌ Not implemented | 🔴 CRITICAL | 2 days | - |
| **DurationTier** | ❌ Not implemented | 🟡 HIGH | 1 day | - |
| **IntensityTier** | ❌ Not implemented | 🟡 HIGH | 1 day | Intensity |
| **FormantGrid** | ❌ Not implemented | 🟡 HIGH | 2 days | Formant |

**Why Critical:**
- Required for pitch/duration modification research
- Enables voice transformation workflows
- PSOLA-based resynthesis is core Praat capability
- Used extensively in prosody and intonation studies

**Example Use Case:**
```r
# Raise pitch by 20%
sound <- Sound$new("recording.wav")
manip <- sound$to_manipulation()
pitch_tier <- manip$extract_pitch_tier()
pitch_tier$multiply_frequencies(from_time = 0, to_time = 0, factor = 1.2)
manip$replace_pitch_tier(pitch_tier)
modified <- manip$get_resynthesis_overlap_add()
modified$save("higher_pitch.wav")
```

**Timeline:** Start after Formant migration, complete within 1.5 weeks

### ❌ Phase 3: Spectral Analysis (NOT STARTED)

| Object | Status | Priority | Effort | Depends On |
|--------|--------|----------|--------|------------|
| **Spectrum** | ❌ Not implemented | 🟡 HIGH | 2 days | Sound |
| **Spectrogram** | ❌ Not implemented | 🟡 HIGH | 2 days | Sound |
| **LPC** | ❌ Not implemented | 🟢 MEDIUM | 2 days | Sound |
| **LTAS** | ❌ Not implemented | 🟢 MEDIUM | 1 day | Spectrum |

**Why Important:**
- Spectral analysis is fundamental to phonetics
- Completes frequency-domain analysis suite
- LPC useful for formant tracking validation

**Timeline:** Start after Manipulation system, complete within 1 week

### ❌ Phase 4: Advanced Analysis (NOT STARTED)

| Object | Status | Priority | Effort | Depends On |
|--------|--------|----------|--------|------------|
| **MFCC** | ❌ Not implemented | 🔵 LOW | 2 days | Sound |
| **Cochleagram** | ❌ Not implemented | 🔵 LOW | 2 days | Sound |
| **Table** | ❌ Not implemented | 🟢 MEDIUM | 1 day | - |
| **Matrix** | ❌ Not implemented | 🟢 MEDIUM | 1 day | - |
| **VoiceReport** | ❌ Not implemented | 🔵 LOW | 3 days | Multiple |

**Timeline:** Implement as needed, estimated 2 weeks total

## Implementation Timeline

### Week 1 (Current)
- [x] **Day 1:** Architecture amendment and planning
- [ ] **Day 2-3:** Formant S3 → R6 migration
- [ ] **Day 4-5:** Begin Manipulation implementation

### Week 2
- [ ] **Day 1-2:** Complete Manipulation + PitchTier
- [ ] **Day 3:** DurationTier + IntensityTier
- [ ] **Day 4:** FormantGrid
- [ ] **Day 5:** Manipulation system testing

### Week 3
- [ ] **Day 1-2:** Spectrum + Spectrogram
- [ ] **Day 3-4:** LPC + LTAS
- [ ] **Day 5:** Spectral analysis testing

### Week 4
- [ ] **Day 1-2:** Complete remaining Sound methods
- [ ] **Day 3:** Complete remaining Pitch methods
- [ ] **Day 4-5:** Documentation and examples

## Detailed Implementation Steps

### IMMEDIATE: Formant S3 → R6 Migration

**Current Files:**
- `R/formant.R` - S3 implementation
- `src/RcppExports.cpp` - C++ bindings exist

**Required Changes:**

1. **Create `R/formant-r6.R`:**
```r
Formant <- R6::R6Class("Formant",
  inherit = PraatObject,
  public = list(
    initialize = function(filepath = NULL, .xptr = NULL) { ... },
    get_value_at_time = function(formant_number, time, unit = "hertz") { ... },
    get_bandwidth_at_time = function(formant_number, time) { ... },
    get_mean = function(formant_number, from_time = 0, to_time = 0) { ... },
    get_standard_deviation = function(formant_number, from_time = 0, to_time = 0) { ... },
    get_minimum = function(formant_number, from_time = 0, to_time = 0, unit = "hertz") { ... },
    get_maximum = function(formant_number, from_time = 0, to_time = 0, unit = "hertz") { ... },
    get_time_of_minimum = function(formant_number, from_time = 0, to_time = 0) { ... },
    get_time_of_maximum = function(formant_number, from_time = 0, to_time = 0) { ... },
    get_number_of_frames = function() { ... },
    get_time_from_frame_number = function(frame_number) { ... },
    to_formant_grid = function() { ... },  # Future: needs FormantGrid
    as_data_frame = function(include_bandwidth = FALSE) { ... },
    as_matrix = function() { ... },
    save = function(filepath) { ... }
  )
)
```

2. **Verify C++ wrappers exist** (check `src/formant-*.cpp`)

3. **Update exports** in `NAMESPACE`

4. **Create tests** in `tests/testthat/test-formant-r6.R`

5. **Deprecate S3** - add `.Deprecated()` to old S3 functions

**Estimated Time:** 4-6 hours

### NEXT: Manipulation System Implementation

**Required C++ Wrappers:**

1. **`src/manipulation-class.cpp`:**
```cpp
// [[Rcpp::export(.manipulation_new)]]
XPtr<structManipulation> manipulation_new(
    XPtr<structSound> sound,
    double time_step,
    double minimum_pitch,
    double maximum_pitch
);

// [[Rcpp::export(.manipulation_extract_pitch_tier)]]
XPtr<structPitchTier> manipulation_extract_pitch_tier(
    XPtr<structManipulation> manip
);

// [[Rcpp::export(.manipulation_replace_pitch_tier)]]
void manipulation_replace_pitch_tier(
    XPtr<structManipulation> manip,
    XPtr<structPitchTier> pitch_tier
);

// [[Rcpp::export(.manipulation_get_resynthesis_overlap_add)]]
XPtr<structSound> manipulation_get_resynthesis_overlap_add(
    XPtr<structManipulation> manip
);
```

2. **`src/pitchtier-class.cpp`:**
```cpp
// [[Rcpp::export(.pitchtier_new)]]
XPtr<structPitchTier> pitchtier_new(double t_min, double t_max);

// [[Rcpp::export(.pitchtier_add_point)]]
void pitchtier_add_point(XPtr<structPitchTier> tier, double time, double value);

// [[Rcpp::export(.pitchtier_multiply_frequencies)]]
void pitchtier_multiply_frequencies(
    XPtr<structPitchTier> tier,
    double from_time,
    double to_time,
    double factor
);
```

**Required R6 Classes:**

1. **`R/manipulation-r6.R`** - See amendment document for full spec
2. **`R/pitchtier-r6.R`** - See amendment document for full spec
3. **`R/durationtier-r6.R`**
4. **`R/intensitytier-r6.R`**
5. **`R/formantgrid-r6.R`**

**Estimated Time:** 1.5 weeks (8-10 working days)

## Testing Strategy

### Unit Tests (Per Object)
- Constructor from file
- Constructor from XPtr
- All query methods
- All transformation methods
- Memory management (no leaks)
- Error handling

### Integration Tests
- Object creation workflows (Sound → Pitch → PitchTier → Manipulation)
- Method chaining
- Export to R data structures
- Round-trip (save and reload)

### Validation Tests
- Compare outputs to Praat desktop
- Use known test files
- Validate numeric accuracy (tolerance for floating-point)

### Performance Tests
- Benchmark vs Praat
- Memory usage profiling
- Large file handling

## Documentation Strategy

### Per Object
- Roxygen2 class documentation
- All method signatures with examples
- Links to Praat manual
- Links to related objects

### Vignettes
1. **Getting Started** - Basic analysis workflow
2. **Praat to R Translation** - Script conversion guide
3. **Pitch Manipulation** - Voice modification workflows
4. **Spectral Analysis** - Frequency-domain analysis
5. **Migration from Parselmouth** - Python to R guide

### Examples (`inst/examples/`)
- Basic analysis pipeline
- Pitch manipulation workflow
- Formant tracking
- Voice quality metrics
- TextGrid-based segmentation
- Re-implementations of Parselmouth examples from superassp

## Success Criteria

- [ ] All Phase 1 objects at 100% method coverage
- [ ] Manipulation system fully functional
- [ ] Spectral analysis objects implemented
- [ ] All tests passing
- [ ] Documentation complete
- [ ] Parselmouth examples ported to R
- [ ] Performance benchmarks comparable to Praat
- [ ] Zero memory leaks (valgrind clean)

## Next Actions

1. ✅ Create architecture amendment document
2. ✅ Update CLAUDE.md with OOP strategy
3. ✅ Commit planning documents
4. **→ BEGIN: Migrate Formant to R6** (IMMEDIATE)
5. Implement Manipulation system
6. Implement spectral objects
7. Complete documentation
8. Port Parselmouth examples

---

**Updated:** 2025-11-10  
**Next Review:** After Formant migration completion
