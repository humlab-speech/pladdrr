# Phase 1+ Module Conversion: Remaining R6 Classes

**Status:** 24/28 objects converted (86%)  
**Remaining:** 4 R6 classes without modules

---

## Not Yet Converted

### 1. FormantTier (Medium Priority)
- **Type:** Tier object for formant manipulation
- **Usage:** Moderate - used in formant manipulation workflows
- **Complexity:** Medium - tier operations with formant frames
- **Module needed:** Yes - can improve performance
- **Estimated effort:** 2-3 hours

### 2. LongSound (Low Priority)
- **Type:** Streaming audio for large files
- **Usage:** Low - mainly for files too large for RAM
- **Complexity:** High - streaming, partial loading
- **Module needed:** Maybe - streaming nature may limit gains
- **Estimated effort:** 3-4 hours
- **Note:** Special case, may not benefit much from modules

### 3. PraatInterpreter (Low Priority - Skip)
- **Type:** Persistent Praat script interpreter
- **Usage:** Moderate - for users needing Praat script compatibility
- **Complexity:** Very High - stateful, complex object management
- **Module needed:** No - inherently stateful, not performance-critical
- **Estimated effort:** 8+ hours
- **Recommendation:** **SKIP** - keep as R6

### 4. VocalTract (Very Low Priority)
- **Type:** Articulatory synthesis
- **Usage:** Very Low - niche functionality
- **Complexity:** Medium
- **Module needed:** No - rarely used
- **Estimated effort:** 2-3 hours
- **Recommendation:** **SKIP** unless requested

---

## Conversion Priority

### High Priority: FormantTier
FormantTier is the only remaining object that:
1. Is commonly used in phonetic research
2. Would benefit from module conversion
3. Is reasonably straightforward to convert

### Skip for Now:
- **PraatInterpreter** - Stateful by design, keep as R6
- **VocalTract** - Too niche
- **LongSound** - Special case, may not benefit

---

## Conversion Plan: FormantTier

### Step 1: Create Module (src/modules/formanttier_module.cpp)

```cpp
// formanttier_module.cpp
class RFormantTier {
private:
    XPtr<structFormantTier> ptr;
    
public:
    RFormantTier(XPtr<structFormantTier> xptr) : ptr(xptr) {}
    
    // Query methods
    double get_xmin();
    double get_xmax();
    int get_number_of_points();
    
    // Point access
    double get_value_at_time(int formant_number, double time);
    
    // Modification
    void add_point(double time, double f1, double b1, ...);
    void remove_point(int index);
    
    // Transform
    XPtr<structFormant> to_formant_ptr();
    XPtr<structSound> filter_sound_ptr(XPtr<structSound> sound);
};

RCPP_MODULE(formanttier_module) {
    class_<RFormantTier>("RFormantTier")
        .constructor<XPtr<structFormantTier>>()
        .method("get_xmin", &RFormantTier::get_xmin)
        // ... etc
    ;
}
```

### Step 2: Convert R6 to Function Wrapper

```r
# R/formanttier-r6.R
FormantTier <- function(.xptr = NULL) {
    # Load module
    mod <- get_module("formanttier_module")
    cpp_ft <- mod$RFormantTier$new(.xptr)
    
    structure(list(
        .cpp = cpp_ft,
        .xptr = .xptr,
        
        # FAST: Module methods
        get_xmin = function() cpp_ft$get_xmin(),
        get_value_at_time = function(formant_number, time) {
            cpp_ft$get_value_at_time(as.integer(formant_number), as.numeric(time))
        },
        
        # COMPLEX: Keep old wrappers if needed
        advanced_operation = function(...) {
            result_ptr <- .formanttier_advanced(.xptr, ...)
            FormantTier(.xptr = result_ptr)
        }
    ), class = c("FormantTier", "PraatObject"))
}
```

### Step 3: Update Factory Calls

Search for `FormantTier$new(.xptr = ...)` → `FormantTier(.xptr = ...)`

### Step 4: Test

- Package installs
- Basic operations work
- Vignettes build (if any)

---

## Decision

**Proceed with FormantTier conversion?**

- ✅ Common enough to matter
- ✅ Straightforward to convert
- ✅ Will complete the "commonly used objects" set
- ✅ Pattern is well-established from 24 previous conversions

**Estimated time:** 2-3 hours for full conversion

After FormantTier, Phase 1+ would be **25/28 (89%)** with all commonly-used objects converted.
