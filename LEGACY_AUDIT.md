# pladdrr Legacy Code Audit

**Date:** 2026-01-07
**Package Version:** 2.0.8
**Purpose:** Document legacy Rcpp wrapper code for future migration to Rcpp modules

---

## Summary

| Metric | Count |
|--------|-------|
| Rcpp Modules | 32 |
| Module methods/properties | 769 |
| Wrapper files | 24 |
| Wrapper exports | ~460 |
| SIMD/Performance files | 18 |
| Performance exports | ~72 |
| **Total exports** | **~532** |

**Key Finding:** `interpreter_wrappers.cpp` (26 exports) has NO corresponding module - only legacy-only wrapper.

---

## Coverage Matrix

### Wrapper Files with Module Equivalents (DUPLICATES)

| Wrapper File | Exports | Module | Module Methods | Recommendation |
|--------------|---------|--------|----------------|----------------|
| `sound_wrappers.cpp` | 61 | `sound_module.cpp` | 43 | REMOVE - highest priority |
| `textgrid_wrappers.cpp` | 39 | `textgrid_module.cpp` | 33 | REMOVE |
| `powercepstrum_wrappers.cpp` | 30 | `powercepstrum_module.cpp` | 38 | REMOVE |
| `pointprocess_wrappers.cpp` | 26 | `pointprocess_module.cpp` | 32 | REMOVE |
| `table_wrappers.cpp` | 26 | `table_module.cpp` | 27 | REMOVE |
| `spectrum_wrappers.cpp` | 25 | `spectrum_module.cpp` | 30 | REMOVE |
| `matrix_wrappers.cpp` | 22 | `matrix_module.cpp` | 27 | REMOVE |
| `formant_wrappers.cpp` | 21 | `formant_module.cpp` | 33 | REMOVE |
| `lpc_wrappers.cpp` | 19 | `lpc_module.cpp` | 26 | REMOVE |
| `formantgrid_wrappers.cpp` | 16 | `formantgrid_module.cpp` | 18 | REMOVE |
| `pitchtier_wrappers.cpp` | 16 | `pitchtier_module.cpp` | 25 | REMOVE |
| `ltas_wrappers.cpp` | 16 | `ltas_module.cpp` | 27 | REMOVE |
| `amplitudetier_wrappers.cpp` | 14 | `amplitudetier_module.cpp` | 23 | REMOVE |
| `longsound_wrappers.cpp` | 13 | `longsound_module.cpp` | 11 | REMOVE |
| `spectrogram_wrappers.cpp` | 13 | `spectrogram_module.cpp` | 36 | REMOVE |
| `intensitytier_wrappers.cpp` | 12 | `intensitytier_module.cpp` | 22 | REMOVE |
| `formanttier_wrappers.cpp` | 11 | `formanttier_module.cpp` | 12 | REMOVE |
| `durationtier_wrappers.cpp` | 11 | `durationtier_module.cpp` | 23 | REMOVE |
| `manipulation_wrappers.cpp` | 11 | `manipulation_module.cpp` | 20 | REMOVE |
| `cochleagram_wrappers.cpp` | 11 | `cochleagram_module.cpp` | 27 | REMOVE |
| `vocaltract_wrappers.cpp` | 11 | `vocaltract_module.cpp` | 10 | REMOVE |
| `excitation_wrappers.cpp` | 9 | `excitation_module.cpp` | 19 | REMOVE |
| `electroglottogram_wrappers.cpp` | 8 | `electroglottogram_module.cpp` | 24 | REMOVE |

**Subtotal:** 23 wrapper files, ~460 exports duplicating module functionality

---

### Legacy-Only Wrapper (NO MODULE)

| Wrapper File | Exports | Module | Recommendation |
|--------------|---------|--------|----------------|
| `interpreter_wrappers.cpp` | 26 | **NONE** | MIGRATE - create `interpreter_module.cpp` |

**Functions requiring migration:**
- `.praat_interpreter_init()` - Initialize Praat library
- `.praat_is_initialized()` - Check initialization state
- `.praat_run_script()` - Execute Praat script text
- `.praat_evaluate_numeric()` - Evaluate expression to number
- `.praat_evaluate_string()` - Evaluate expression to string
- `.praat_evaluate_vector()` - Evaluate to numeric vector
- `.praat_evaluate_matrix()` - Evaluate to matrix
- `.praat_evaluate_string_array()` - Evaluate to string array
- `.praat_interpreter_create()` - Create interpreter instance
- `.praat_interpreter_run()` - Run script on interpreter
- `.praat_interpreter_get_variable()` - Get variable value
- `.praat_interpreter_set_variable()` - Set variable value
- `.praat_interpreter_eval_*()` - Various evaluation methods
- `.praat_interpreter_object_count()` - Count objects in list
- `.praat_interpreter_list_objects()` - List all objects
- `.praat_interpreter_get_object()` - Get object by name
- `.praat_interpreter_get_object_by_id()` - Get object by ID
- `.praat_interpreter_set_object()` - Add object to list
- `.praat_interpreter_remove_object()` - Remove object by name
- `.praat_interpreter_select_object()` - Select object
- `.praat_interpreter_clear_objects()` - Clear all objects

---

## Interpreter Module Feasibility Analysis

### Current Implementation Structure

The `interpreter_wrappers.cpp` contains **three distinct function categories**:

#### Category 1: Stateless Expression Evaluation (8 functions)
```cpp
// Each call creates temporary interpreter, evaluates, destroys
autoInterpreter interpreter = Interpreter_create();
double value;
Interpreter_numericExpression(interpreter.get(), expr, &value);
return value;
```

**Functions:** `praat_run_script`, `praat_evaluate_numeric`, `praat_evaluate_string`, `praat_evaluate_vector`, `praat_evaluate_matrix`, `praat_evaluate_string_array`

**Module compatibility:** YES - but low value (temporary objects)

#### Category 2: Persistent Interpreter Instance (10 functions)
```cpp
// Already uses XPtr pattern internally!
// [[Rcpp::export(.praat_interpreter_create)]]
SEXP praat_interpreter_create() {
    autoInterpreter interpreter = Interpreter_create();
    return create_xptr_from_auto<structInterpreter>(interpreter);
}

// [[Rcpp::export(.praat_interpreter_run)]]
void praat_interpreter_run(SEXP xptr, std::string script) {
    XPtr<structInterpreter> interpreter(xptr);
    Interpreter_run(interpreter.get(), text.get(), true);
}
```

**Functions:** `praat_interpreter_create`, `praat_interpreter_run`, `praat_interpreter_get_variable`, `praat_interpreter_set_variable`, `praat_interpreter_eval_numeric`, `praat_interpreter_eval_string`, `praat_interpreter_eval_vector`, `praat_interpreter_eval_matrix`, `praat_interpreter_eval_string_array`

**Module compatibility:** YES - ideal candidate, already XPtr-based

#### Category 3: Global Object List Operations (8 functions)
```cpp
// Accesses global singleton theCurrentPraatObjects
int praat_interpreter_object_count() {
    return theCurrentPraatObjects->n;  // Global state!
}
```

**Functions:** `praat_interpreter_object_count`, `praat_interpreter_list_objects`, `praat_interpreter_get_object`, `praat_interpreter_get_object_by_id`, `praat_interpreter_set_object`, `praat_interpreter_remove_object`, `praat_interpreter_remove_object_by_id`, `praat_interpreter_select_object`, `praat_interpreter_clear_objects`

**Module compatibility:** PARTIAL - operates on global singleton, not instance state

---

### Architectural Challenges

#### Challenge 1: Global Praat Initialization

```cpp
static bool praat_interpreter_initialized = false;

void praat_interpreter_init() {
    praatlib_init();           // Global library init
    praat_uvafon_init();       // Register all object classes
}
```

**Issue:** One-time global initialization, not per-instance.

**Solution:** Keep as package-level init in `.onLoad()`, not in module.

#### Challenge 2: Global Object List Singleton

```cpp
// theCurrentPraatObjects is a global variable in Praat
// All scripts share this single object list
theCurrentPraatObjects->n;
theCurrentPraatObjects->list[iobject].object;
```

**Issue:** Not instance state - all interpreters share one object list.

**Solution Options:**
1. **Static methods in module** - awkward but possible
2. **Keep as standalone exports** - cleaner, matches reality
3. **Separate `PraatObjectList` class** - misleading (suggests multiple lists)

**Recommendation:** Keep global object list functions as `[[Rcpp::export]]` - they genuinely operate on package-level global state, not interpreter instances.

#### Challenge 3: Variable Persistence

```cpp
// Interpreter variables persist between run() calls
Interpreter_run(interpreter.get(), text.get(), true);  // true = reuse variables
```

**Issue:** None - this is exactly what modules handle well via instance state.

**Solution:** `RInterpreter` class naturally preserves `XPtr<structInterpreter>` between method calls.

---

### Recommended Module Design

```cpp
// interpreter_module.cpp

class RInterpreter {
private:
    XPtr<structInterpreter> ptr;

public:
    // Constructor - creates persistent interpreter
    RInterpreter() {
        ensure_praat_initialized();  // Package-level init
        autoInterpreter interp = Interpreter_create();
        addPredefinedVariables(interp.get());
        ptr = create_xptr_from_auto<structInterpreter>(interp);
    }

    // Instance methods - operate on this interpreter's state
    void run(std::string script);
    double eval_numeric(std::string expr);
    std::string eval_string(std::string expr);
    NumericVector eval_vector(std::string expr);
    NumericMatrix eval_matrix(std::string expr);
    CharacterVector eval_string_array(std::string expr);
    SEXP get_variable(std::string name);
    void set_variable(std::string name, SEXP value);
};

RCPP_MODULE(interpreter_module) {
    class_<RInterpreter>("RInterpreter")
        .constructor()
        .method("run", &RInterpreter::run)
        .method("eval_numeric", &RInterpreter::eval_numeric)
        .method("eval_string", &RInterpreter::eval_string)
        .method("eval_vector", &RInterpreter::eval_vector)
        .method("eval_matrix", &RInterpreter::eval_matrix)
        .method("eval_string_array", &RInterpreter::eval_string_array)
        .method("get_variable", &RInterpreter::get_variable)
        .method("set_variable", &RInterpreter::set_variable)
        ;
}
```

### Functions to Keep as Standalone Exports

```cpp
// These operate on global Praat state, not interpreter instances
// Keep as [[Rcpp::export]] in interpreter_wrappers.cpp or praat_wrapper.cpp

// Package initialization (called from .onLoad)
void praat_interpreter_init();
bool praat_is_initialized();

// Global object list operations
int praat_interpreter_object_count();
DataFrame praat_interpreter_list_objects();
SEXP praat_interpreter_get_object(std::string name, std::string expected_type);
SEXP praat_interpreter_get_object_by_id(int id);
int praat_interpreter_set_object(SEXP xptr, std::string name, std::string class_name);
void praat_interpreter_remove_object(std::string name);
void praat_interpreter_remove_object_by_id(int id);
void praat_interpreter_select_object(std::string name, bool add);
void praat_interpreter_clear_objects();

// Stateless convenience functions (optional - could remove)
void praat_run_script(std::string script_text);
double praat_evaluate_numeric(std::string expression);
// ... etc
```

---

### Migration Summary

| Function Category | Count | Module Compatible | Recommendation |
|-------------------|-------|-------------------|----------------|
| Persistent interpreter methods | 10 | **YES** | Migrate to `RInterpreter` class |
| Global object list operations | 8 | PARTIAL | Keep as standalone exports |
| Stateless evaluation | 6 | YES (low value) | Keep as convenience functions |
| Package initialization | 2 | NO | Keep as infrastructure |

**Conclusion:** ~10 of 26 functions can be cleanly migrated to an Rcpp module (`RInterpreter` class). The remaining 16 functions operate on global state and should remain as `[[Rcpp::export]]` functions, possibly reorganized into `praat_globals.cpp`.

---

### Performance/SIMD Files (KEEP)

These use direct `[[Rcpp::export]]` intentionally for performance - bypassing module overhead.

| File | Exports | Purpose | Recommendation |
|------|---------|---------|----------------|
| `autocorrelation_simd.cpp` | 15 | SIMD autocorrelation | KEEP |
| `window_functions_simd.cpp` | 9 | SIMD windowing | KEEP |
| `batch_queries.cpp` | 8 | Batch property extraction | KEEP |
| `sound_zerocopy.cpp` | 4 | Zero-copy array access | KEEP |
| `intensity_simd.cpp` | 3 | SIMD intensity | KEEP |
| `num_matrix_simd.cpp` | 3 | SIMD matrix ops | KEEP |
| `textgrid_batch_operations.cpp` | 3 | Batch TextGrid ops | KEEP |
| `num_distance_simd.cpp` | 2 | SIMD distance | KEEP |
| `sound_mixing_simd.cpp` | 2 | SIMD mixing | KEEP |
| `pitch_processing_simd.cpp` | 2 | SIMD pitch | KEEP |
| `sound_conversion_simd.cpp` | 1 | SIMD conversion | KEEP |
| `sound_statistics_simd.cpp` | 1 | SIMD statistics | KEEP |
| `sound_convolution_simd.cpp` | 1 | SIMD convolution | KEEP |
| `simd_info.cpp` | 1 | SIMD capability info | KEEP |
| `utils.cpp` | 1 | Utility functions | KEEP |

**Subtotal:** 15 files, ~56 exports - intentional performance optimizations

---

### Utility/Infrastructure Files (KEEP)

| File | Exports | Purpose | Recommendation |
|------|---------|---------|----------------|
| `praat_wrapper.cpp` | 8 | Praat init/cleanup | KEEP - infrastructure |
| `sound_module_poc.cpp` | 1 | Proof of concept | REMOVE - obsolete |

---

## Module Inventory

### Complete Module List (32 modules, 769 methods/properties)

| Module | Methods | R Wrapper File |
|--------|---------|----------------|
| `sound_module` | 43 | `sound-r6-new.R` |
| `pitch_module` | 42 | `pitch-r6.R` |
| `powercepstrum_module` | 38 | `powercepstrum-r6.R` |
| `spectrogram_module` | 36 | `spectrogram-r6.R` |
| `textgrid_module` | 33 | `textgrid-r6.R` |
| `formant_module` | 33 | `formant-r6.R` |
| `pointprocess_module` | 32 | `pointprocess-r6.R` |
| `spectrum_module` | 30 | `spectrum-r6.R` |
| `intensity_module` | 30 | `intensity-r6.R` |
| `matrix_module` | 27 | `matrix-r6.R` |
| `ltas_module` | 27 | `ltas-r6.R` |
| `cochleagram_module` | 27 | `cochleagram-r6.R` |
| `table_module` | 27 | `table-r6.R` |
| `harmonicity_module` | 27 | `harmonicity-r6.R` |
| `lpc_module` | 26 | `lpc-r6.R` |
| `pitchtier_module` | 25 | `pitchtier-r6.R` |
| `electroglottogram_module` | 24 | `electroglottogram-r6.R` |
| `amplitudetier_module` | 23 | `amplitudetier-r6.R` |
| `durationtier_module` | 23 | `durationtier-r6.R` |
| `intensitytier_module` | 22 | `intensitytier-r6.R` |
| `manipulation_module` | 20 | `manipulation-r6.R` |
| `formantpath_module` | 20 | `formantpath-r6.R` |
| `excitation_module` | 19 | `excitation-r6.R` |
| `formantgrid_module` | 18 | `formantgrid-r6.R` |
| `klattgrid_module` | 17 | `klattgrid-r6.R` |
| `cepstrum_module` | 17 | `cepstrum-r6.R` |
| `complexspectrogram_module` | 17 | `complexspectrogram-r6.R` |
| `formanttier_module` | 12 | `formanttier-r6.R` |
| `polygon_module` | 12 | `polygon-r6.R` |
| `longsound_module` | 11 | `longsound-r6.R` |
| `vocaltract_module` | 10 | `vocaltract-r6.R` |
| `sound_operations_module` | - | (internal) |

---

## Migration Roadmap

### Phase 1: Remove Duplicate Wrappers (HIGH PRIORITY)

**Impact:** ~460 exports, ~10K lines of code, ~40% binary size reduction

**Order by priority:**
1. `sound_wrappers.cpp` (61 exports) - largest, most used
2. `textgrid_wrappers.cpp` (39 exports) - second largest
3. `powercepstrum_wrappers.cpp` (30 exports)
4. `pointprocess_wrappers.cpp` (26 exports)
5. `table_wrappers.cpp` (26 exports)
6. ... remaining 18 wrapper files

**Steps per file:**
1. Verify all wrapper functions have module equivalents
2. Update any R code using wrapper functions to use module
3. Remove wrapper file from `src/`
4. Update `Makevars` if needed
5. Run `Rcpp::compileAttributes()`
6. Run tests

### Phase 2: Create Interpreter Module (MEDIUM PRIORITY)

**Impact:** 26 exports migrated to proper OOP pattern

**Status:** ✅ COMPLETE (2026-01-07)

**Implementation:**
- Created `src/modules/interpreter_module.cpp` with `RInterpreter` class
- Migrated 10 persistent interpreter methods to module:
  - `run()` - Execute Praat script
  - `eval_numeric()`, `eval_string()`, `eval_vector()`, `eval_matrix()`, `eval_string_array()`
  - `get_variable()`, `set_variable()`
  - `is_valid()`, `get_xptr()`
- Updated `R/praat-interpreter-r6.R` to use module for instance methods
- Kept global object list operations (8 functions) as `[[Rcpp::export]]` wrappers
- Kept stateless evaluation (6 functions) and init (2 functions) as wrappers

**Design:**
```cpp
class RInterpreter {
    XPtr<structInterpreter> ptr;
public:
    RInterpreter();
    void run(std::string script);
    double eval_numeric(std::string expr);
    std::string eval_string(std::string expr);
    NumericVector eval_vector(std::string expr);
    NumericMatrix eval_matrix(std::string expr);
    CharacterVector eval_string_array(std::string expr);
    SEXP get_variable(std::string name);
    void set_variable(std::string name, SEXP value);
};

RCPP_MODULE(interpreter_module) {
    class_<RInterpreter>("RInterpreter")
        .constructor()
        .method("run", &RInterpreter::run)
        .method("eval_numeric", &RInterpreter::eval_numeric)
        .method("eval_string", &RInterpreter::eval_string)
        .method("eval_vector", &RInterpreter::eval_vector)
        .method("eval_matrix", &RInterpreter::eval_matrix)
        .method("eval_string_array", &RInterpreter::eval_string_array)
        .method("get_variable", &RInterpreter::get_variable)
        .method("set_variable", &RInterpreter::set_variable)
        .method("is_valid", &RInterpreter::is_valid)
        .method("get_xptr", &RInterpreter::get_xptr);
}
```

**Files Modified:**
- Created: `src/modules/interpreter_module.cpp`
- Modified: `R/praat-interpreter-r6.R` (updated to use module)
- Preserved: `src/interpreter_wrappers.cpp` (still needed for global operations)

### Phase 3: Audit Performance Files (LOW PRIORITY)

Review SIMD files for:
- Unused functions
- Consolidation opportunities
- Documentation

---

## File Locations

```
src/
├── modules/                    # 32 Rcpp modules (KEEP)
│   ├── sound_module.cpp
│   ├── pitch_module.cpp
│   └── ...
├── *_wrappers.cpp              # 24 legacy wrappers (23 REMOVE, 1 MIGRATE)
├── *_simd.cpp                  # 15 SIMD files (KEEP)
├── sound_zerocopy.cpp          # Zero-copy (KEEP)
├── batch_queries.cpp           # Batch ops (KEEP)
├── textgrid_batch_operations.cpp # Batch ops (KEEP)
├── praat_wrapper.cpp           # Infrastructure (KEEP)
├── utils.cpp                   # Utilities (KEEP)
└── sound_module_poc.cpp        # Obsolete (REMOVE)
```

---

## Dependencies

### R Code Using Wrappers

Check `R/RcppExports.R` for generated wrapper functions. These call:
- `.Call(_pladdrr_<function_name>, ...)`

Before removing any wrapper, search R code for:
```r
grep -r "_pladdrr_<wrapper_function>" R/
```

### External Package Dependencies

None - all Praat code is embedded.

---

## Risks

1. **Breaking changes:** R code may call wrapper functions directly
2. **Performance regression:** Module method dispatch adds ~17µs overhead
3. **Binary size:** Temporary increase during migration if both kept

## Mitigation

1. Run full test suite after each removal
2. Keep SIMD/batch functions as direct exports
3. Remove wrappers incrementally, not all at once
