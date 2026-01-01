# Phase 2 Status: High-Value Missing Classes

**Date**: 2026-01-01  
**Version**: 1.9.0  
**Status**: IN PROGRESS (1/5 modules complete)

---

## Overview

Phase 2 adds 5 high-value Praat classes that were missing from the original 27 modules.

**Goal**: Expand coverage from 28% (27/96) to 33% (32/96) of Praat classes.

---

## Progress

### ✅ Task 2.1: Polygon Module (COMPLETE)

**Status**: Working  
**Files**:
- `src/modules/polygon_module.cpp` (224 lines)
- `R/polygon-module.R` (150 lines)
- `man/Polygon.Rd`

**Implemented**:
- ✅ Create from x/y vectors
- ✅ Get number of points
- ✅ Get x/y coordinates (individual and all)
- ✅ Get perimeter
- ✅ Export to data.frame / matrix
- ✅ Save to file
- ⚠️  Randomize (has XPtr const issue, commented out)
- ⚠️  Optimize salesperson (has XPtr const issue, commented out)

**Test Results**:
```r
poly <- Polygon(x = c(0, 1, 1, 0), y = c(0, 0, 1, 1))
poly$n_points()       # 4
poly$get_perimeter()  # 4.0
df <- as.data.frame(poly)  # Works
```

**Known Issues**:
- Mutating methods (randomize, optimize_salesperson) cause segfault
- Issue: XPtr constness preventing in-place modification
- Workaround: Disabled for now, can fix in Phase 2+ if needed

**Use Cases**:
- Vowel space boundaries
- Formant space visualization
- Acoustic space analysis

---

### 🔄 Task 2.2: FormantPath Module (IN PROGRESS)

**Status**: Starting  
**Estimated effort**: 4-5 days  
**Priority**: HIGH

**Planned features**:
- Multiple formant tracking paths
- Automatic optimal path selection
- Path stress calculation
- Extract optimal formant result

**Use cases**:
- Robust formant tracking
- Automatic formant selection
- Formant tracking optimization

---

### ⏳ Task 2.3: KlattGrid Module (PENDING)

**Estimated effort**: 6-8 days  
**Priority**: HIGH

**Planned features**:
- Speech synthesis from parameters
- Tier-based parameter control
- Voice simulation

---

### ⏳ Task 2.4: ComplexSpectrogram Module (PENDING)

**Estimated effort**: 3-4 days  
**Priority**: MEDIUM

**Planned features**:
- Phase information preservation
- Complex FFT operations
- Advanced spectral analysis

---

### ⏳ Task 2.5: Harmonics Module (PENDING)

**Estimated effort**: 2-3 days  
**Priority**: MEDIUM

**Planned features**:
- Harmonic series analysis
- Overtone extraction
- Harmonic-to-noise ratio

---

## Timeline

| Task | Duration | Status | Completion |
|------|----------|--------|------------|
| 2.1: Polygon | 2-3 days | ✅ DONE | 2026-01-01 |
| 2.2: FormantPath | 4-5 days | 🔄 IN PROGRESS | TBD |
| 2.3: KlattGrid | 6-8 days | ⏳ PENDING | TBD |
| 2.4: ComplexSpectrogram | 3-4 days | ⏳ PENDING | TBD |
| 2.5: Harmonics | 2-3 days | ⏳ PENDING | TBD |
| **TOTAL** | **17-25 days** | **20% complete** | - |

---

## Version History

### v1.9.0 (2026-01-01)
- ✅ Added Polygon module (Phase 2.1)
- ✅ Fixed sound_wrappers.cpp archive issue
- ✅ Regenerated RcppExports.cpp
- ✅ Fixed NAMESPACE syntax
- ✅ 28 modules total (27 original + 1 new)

### v1.8.1 (2025-12-31)
- Module preloading optimization

### v1.8.0 (2025-12-31)
- Phase 1+ cleanup complete
- 40% binary reduction
- 50% faster compile

---

## Technical Notes

### Module Pattern (Established with Polygon)

**C++ side** (`src/modules/polygon_module.cpp`):
```cpp
// Free function for factory (returns XPtr)
XPtr<structPolygon> polygon_create_xptr(NumericVector x, NumericVector y) { ... }

class RPolygon {
    XPtr<structPolygon> ptr;
    // Constructor from XPtr
    RPolygon(XPtr<structPolygon> p) : ptr(p) {}
    // Methods...
};

RCPP_MODULE(polygon_module) {
    class_<RPolygon>("RPolygon")
        .constructor<XPtr<structPolygon>>()
        .method(...)
    ;
    function("polygon_create_xptr", &polygon_create_xptr);
}
```

**R side** (`R/polygon-module.R`):
```r
Polygon <- function(x, y) {
    poly_mod <- get_module("polygon_module")
    xptr <- poly_mod$polygon_create_xptr(x, y)
    cpp_obj <- poly_mod$RPolygon$new(xptr)
    
    # Wrapper with convenience methods
    obj <- structure(list(
        .cpp = cpp_obj,
        method1 = function(...) cpp_obj$method1(...),
        # ...
    ), class = c("Polygon", "PraatObject"))
    obj
}
```

### Lessons Learned

1. **XPtr factory pattern**: Free functions returning XPtr work better than static class methods
2. **Const issues**: Be careful with methods that modify in-place (may need wrapper objects)
3. **Archive cleanup**: Always check for leftover wrapper files before module conversion
4. **NAMESPACE hygiene**: Roxygen can generate malformed S3method entries, manual fixes needed

---

## Next Steps (FormantPath)

1. Study Praat's FormantPath.h/cpp implementation
2. Create `src/modules/formantpath_module.cpp`
3. Implement core methods:
   - Get number of paths
   - Get path by index
   - Find optimal path
   - Get path stress
   - Extract optimal formant
4. Create R wrapper `R/formantpath-module.R`
5. Add tests and documentation
6. Update Makevars to include formantpath_module
7. Add to .onLoad preload list

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-01  
**Package Version**: 1.9.0
