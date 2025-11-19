# Praat Script Interpreter Implementation Plan for Speaker Package

**Analysis Date**: 2025-11-18
**Speaker Package Location**: `/Users/frkkan96/Documents/src/speaker`
**Target**: Add Praat script interpretation capability to speaker R package

---

## Executive Summary

This document provides a comprehensive plan for implementing a Praat script interpreter in the **speaker** R package. The implementation will leverage Praat's existing C++ `Interpreter` class while providing R-idiomatic interfaces for script execution, variable access, and object management.

### Implementation Approach: **WRAP & EXTEND**

Rather than reimplementing Praat's interpreter from scratch, we will:
1. **Wrap** Praat's existing `Interpreter` C++ class using Rcpp
2. **Extend** with R-friendly interfaces for script execution
3. **Bridge** between Praat's object system and speaker's R6 classes
4. **Manage** object lifetimes between interpreter and R environments

---

## Part 1: Current Speaker Architecture Analysis

### 1.1 Architecture Overview

**Design Pattern**: R6 Classes + Rcpp External Pointers + C++ Wrappers

```
┌─────────────────────────────────────────────────────────────┐
│ R Layer                                                      │
│                                                              │
│  ┌──────────────┐   inherits   ┌──────────────┐           │
│  │ PraatObject  │◄─────────────│    Sound     │           │
│  │  (abstract)  │              │   Pitch      │           │
│  │              │              │   Formant    │           │
│  │ - ptr        │              │   TextGrid   │           │
│  │ - initialize │              │   etc.       │           │
│  │ - is_valid() │              │              │           │
│  └──────────────┘              └──────────────┘           │
│         │                               │                   │
│         │ manages                       │ wraps             │
│         ▼                               ▼                   │
├─────────────────────────────────────────────────────────────┤
│ C++ Layer (via Rcpp)                                        │
│                                                              │
│  ┌────────────────┐         ┌──────────────────┐           │
│  │ External Ptr   │────────►│ Praat C++ Object │           │
│  │ (SEXP XPtr)    │         │ (autoSound,      │           │
│  │                │         │  autoPitch, etc.)│           │
│  └────────────────┘         └──────────────────┘           │
│         │                                                    │
│         │ called by                                         │
│         ▼                                                    │
│  ┌─────────────────────────────────────┐                   │
│  │  sound_wrappers.cpp                  │                   │
│  │  pitch_wrappers.cpp                  │                   │
│  │  formant_wrappers.cpp                │                   │
│  │  (Rcpp RCPP_MODULE exports)         │                   │
│  └─────────────────────────────────────┘                   │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Existing R6 Classes

Located in `/Users/frkkan96/Documents/src/speaker/R/`:

| **Class** | **File** | **Status** | **Key Methods** |
|-----------|----------|------------|-----------------|
| PraatObject | `praat-object.R` | Base class | `initialize()`, `is_valid()` |
| Sound | `sound-r6-new.R` | ✅ Complete | `to_pitch()`, `to_formant()`, `to_intensity()` |
| Pitch | `pitch-r6.R` | ✅ Complete | `get_mean()`, `get_minimum()`, `get_maximum()` |
| Formant | `formant-r6.R` | ✅ Complete | `get_value_at_time()`, `track()` |
| TextGrid | `textgrid-r6.R` | ✅ Complete | `add_tier()`, `get_intervals()`, `as_data_frame()` |
| Intensity | `intensity-r6.R` | ✅ Complete | `get_mean()`, `get_minimum()`, `get_maximum()` |
| Spectrogram | `spectrogram-r6.R` | ✅ Complete | Query methods |
| Spectrum | `spectrum-r6.R` | ✅ Complete | Spectral analysis methods |
| Harmonicity | `harmonicity.R` | ✅ Complete | HNR calculations |
| PointProcess | `pointprocess-r6.R` | ✅ Complete | Jitter/shimmer |
| Manipulation | `manipulation-r6.R` | ✅ Complete | PSOLA manipulation |
| PitchTier | `pitchtier-r6.R` | ✅ Complete | Point manipulation |
| IntensityTier | `intensitytier-r6.R` | ✅ Complete | Point manipulation |
| DurationTier | `durationtier-r6.R` | ✅ Complete | Duration manipulation |
| Ltas | `ltas-r6.R` | ✅ Complete | Long-term spectrum |
| LPC | `lpc-r6.R` | ✅ Complete | LPC analysis |
| Matrix | `matrix-r6.R` | ✅ Complete | Generic matrix operations |
| FormantGrid | `formantgrid-r6.R` | ✅ Complete | Formant synthesis |

### 1.3 C++ Wrapper Pattern

Located in `/Users/frkkan96/Documents/src/speaker/src/`:

**Example: sound_wrappers.cpp pattern**
```cpp
// External pointer with finalizer
SEXP snd_create_from_file(std::string path) {
    try {
        autoSound sound = Sound_readFromSoundFile(Melder_peek32to8(path.c_str()));
        return Rcpp::XPtr<structSound>(sound.releaseToAmbiguousOwner());
    } catch (MelderError) {
        // Error handling
    }
}

// Methods that accept XPtr
double snd_get_duration(SEXP xptr) {
    Rcpp::XPtr<structSound> sound_ptr(xptr);
    return sound_ptr->xmax - sound_ptr->xmin;
}

// Export via Rcpp
RCPP_MODULE(sound_module) {
    using namespace Rcpp;
    function("snd_create_from_file", &snd_create_from_file);
    function("snd_get_duration", &snd_get_duration);
    // ... more functions
}
```

**Key Patterns**:
1. External pointers manage C++ Praat objects
2. `auto*` types (autoSound, autoPitch) ensure memory safety
3. `.releaseToAmbiguousOwner()` transfers ownership to R
4. Rcpp modules export C++ functions to R
5. R6 classes wrap these C++ functions with OOP interface

---

## Part 2: Praat Interpreter Architecture

### 2.1 Praat's Interpreter Class Structure

**Source**: `/Users/frkkan96/Documents/src/speaker/src/praat/sys/Interpreter.h`

**Key Components**:

```cpp
Thing_define (Interpreter, Thing) {
    // Script management
    Script scriptReference;
    Notebook notebookReference;

    // Variable storage
    std::unordered_map<std::u32string, autoInterpreterVariable> variablesMap;

    // Parameters and arguments (for form/procedure calls)
    int numberOfParameters;
    char32 parameters[1+Interpreter_MAXNUM_PARAMETERS][1+Interpreter_MAX_PARAMETER_LENGTH];
    autostring32 arguments[1+Interpreter_MAXNUM_PARAMETERS];

    // Labels (for goto statements - though deprecated)
    int numberOfLabels;
    char32 labelNames[1+Interpreter_MAXNUM_LABELS][1+Interpreter_MAX_LABEL_LENGTH];
    integer labelLines[1+Interpreter_MAXNUM_LABELS];

    // Execution state
    bool running, stopped;
    autovector<mutablestring32> lines;   // script lines
    integer lineNumber;

    // Return values (for procedure calls)
    kInterpreter_ReturnType returnType;
    bool returnedBoolean;
    autostring32 returnedString;
    autoVEC returnedRealVector;
    autoMAT returnedRealMatrix;
    autoSTRVEC returnedStringArray;

    // Call stack
    int callDepth;
    char32 procedureNames[1+Interpreter_MAX_CALL_DEPTH][100];

    // Editor environment (for interactive use)
    struct EditorEnvironment {
        ClassInfo _optionalClass;
        Editor _optionalInstance;
    } _owningEditorEnvironment, _dynamicEditorEnvironment;
};
```

### 2.2 Variable Types in Praat Scripts

```cpp
Thing_define (InterpreterVariable, SimpleString) {
    double numericValue;               // foo (real/int/boolean)
    autostring32 stringValue;          // foo$
    autoVEC numericVectorValue;        // foo#
    autoMAT numericMatrixValue;        // foo##
    autoSTRVEC stringArrayValue;       // foo$#
};
```

**Variable Naming Conventions**:
- `var` → numeric (double)
- `var$` → string
- `var#` → numeric vector
- `var##` → numeric matrix
- `var$#` → string array

### 2.3 Script Execution Functions

**Source**: `/Users/frkkan96/Documents/src/speaker/src/praat/sys/praat_script.h`

```cpp
// Main execution functions
void praat_executeScriptFromFile(MelderFile file, conststring32 arguments, Editor optionalEditor);
void praat_executeScriptFromText(conststring32 text);
bool praat_executeCommand(Interpreter me, char32 *command);

// Argument parsing
integer Interpreter_readParameters(Interpreter me, mutablestring32 text);
void Interpreter_getArgumentsFromString(Interpreter me, conststring32 arguments);
void Interpreter_getArgumentsFromArgs(Interpreter me, integer nargs, Stackel args);
```

---

## Part 3: Interpreter Implementation Design

### 3.1 High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│ R User Interface                                              │
│                                                               │
│  praat_script <- PraatScript$new()                           │
│  praat_script$execute("script.praat")                        │
│  praat_script$set_variable("soundFile$", "test.wav")        │
│  result <- praat_script$get_variable("pitch_mean")          │
│                                                               │
├──────────────────────────────────────────────────────────────┤
│ R6 Wrapper Layer (New)                                       │
│                                                               │
│  ┌─────────────────────────────────────┐                    │
│  │  PraatScript R6 Class               │                    │
│  │                                      │                    │
│  │  - interpreter_ptr (XPtr)           │                    │
│  │  - object_registry (environment)     │                    │
│  │                                      │                    │
│  │  Methods:                            │                    │
│  │  + execute(script_path/text)        │                    │
│  │  + eval(command)                     │                    │
│  │  + set_variable(name, value)        │                    │
│  │  + get_variable(name)                │                    │
│  │  + select_object(name/id)           │                    │
│  │  + get_object(name/id) → R6 object  │                    │
│  │  + list_variables()                  │                    │
│  │  + list_objects()                    │                    │
│  │  + reset()                           │                    │
│  └─────────────────────────────────────┘                    │
│                │                                              │
│                │ calls                                        │
│                ▼                                              │
├──────────────────────────────────────────────────────────────┤
│ Rcpp Bridge Layer (New)                                      │
│                                                               │
│  ┌───────────────────────────────────────┐                  │
│  │  interpreter_wrappers.cpp             │                  │
│  │                                        │                  │
│  │  - interp_create()                    │                  │
│  │  - interp_execute_script(xptr, path)  │                  │
│  │  - interp_execute_text(xptr, text)    │                  │
│  │  - interp_eval_command(xptr, command) │                  │
│  │  - interp_set_variable(xptr, name, val)│                 │
│  │  - interp_get_variable(xptr, name)    │                  │
│  │  - interp_get_selected_objects(xptr)  │                  │
│  │  - interp_destroy(xptr)               │                  │
│  └───────────────────────────────────────┘                  │
│                │                                              │
│                │ interfaces with                             │
│                ▼                                              │
├──────────────────────────────────────────────────────────────┤
│ Praat C++ Layer (Existing)                                   │
│                                                               │
│  ┌─────────────────────────────────┐                        │
│  │  Praat Interpreter               │                        │
│  │  (Interpreter.cpp/.h)            │                        │
│  │                                  │                        │
│  │  - Script parsing                │                        │
│  │  - Variable management           │                        │
│  │  - Command execution             │                        │
│  │  - Object selection              │                        │
│  │  - Formula evaluation            │                        │
│  └─────────────────────────────────┘                        │
│                │                                              │
│                │ manipulates                                  │
│                ▼                                              │
│  ┌─────────────────────────────────┐                        │
│  │  Praat Object System             │                        │
│  │  (Thing, Collection, Data)       │                        │
│  └─────────────────────────────────┘                        │
└──────────────────────────────────────────────────────────────┘
```

### 3.2 Object Lifecycle Management

**Challenge**: Objects created in Praat interpreter must be accessible from R and vice versa.

**Solution**: Bidirectional Object Registry

```cpp
// C++ side: Map Praat objects to R XPtrs
std::unordered_map<integer, SEXP> praat_to_r_objects;

// R side: Environment storing R6 objects by ID
object_registry <- new.env(parent = emptyenv())
object_registry[[id]] <- sound_r6_object
```

**Workflow**:
1. **Praat script creates object**: `sound = Read from file: "test.wav"`
   - Praat creates `Sound` object with ID (e.g., 42)
   - C++ wrapper extracts it, creates XPtr
   - Registers in `praat_to_r_objects[42] = xptr`
   - R6 `Sound` object created, stored in `object_registry[["42"]]`

2. **R creates object, passes to script**:
   ```r
   sound <- Sound$new("test.wav")
   praat_script$register_object("my_sound", sound)
   praat_script$eval("selectObject: 'my_sound'")
   ```
   - R6 object's XPtr extracted
   - Registered in Praat interpreter's object list
   - Name "my_sound" mapped to Praat ID

### 3.3 Variable Bridging

**Praat → R**:
```r
# In script: pitch_mean = Get mean: 0, 0, "Hertz"
pitch_mean <- praat_script$get_variable("pitch_mean")  # Returns numeric
```

**R → Praat**:
```r
praat_script$set_variable("threshold", 0.5)
praat_script$set_variable("filename$", "output.wav")
praat_script$set_variable("formants#", c(800, 1200, 2500))
```

**Implementation**:
```cpp
SEXP interp_get_variable(SEXP interp_xptr, std::string name) {
    Rcpp::XPtr<structInterpreter> interp(interp_xptr);

    // Look up in variablesMap
    auto var_u32 = Melder_peek8to32(name.c_str());
    auto it = interp->variablesMap.find(var_u32);

    if (it == interp->variablesMap.end())
        return R_NilValue;

    auto& var = it->second;

    // Determine type by name suffix
    if (Melder_endsWith(var_u32, U"$"))
        return Rcpp::wrap(Melder_peek32to8(var->stringValue.get()));
    else if (Melder_endsWith(var_u32, U"##"))
        return Rcpp::wrap(var->numericMatrixValue.get());
    else if (Melder_endsWith(var_u32, U"#"))
        return Rcpp::wrap(var->numericVectorValue.get());
    else
        return Rcpp::wrap(var->numericValue);
}
```

---

## Part 4: Implementation Phases

### Phase 1: Minimal Viable Interpreter (2-3 weeks)

**Goal**: Execute simple Praat scripts without R6 integration

**Components**:
1. **C++ Wrapper** (`src/interpreter_wrappers.cpp`):
   ```cpp
   SEXP interp_create();
   void interp_execute_text(SEXP xptr, std::string script_text);
   SEXP interp_get_variable(SEXP xptr, std::string name);
   void interp_set_variable_numeric(SEXP xptr, std::string name, double value);
   void interp_set_variable_string(SEXP xptr, std::string name, std::string value);
   ```

2. **R6 Class** (`R/praat-script.R`):
   ```r
   PraatScript <- R6Class("PraatScript",
     public = list(
       initialize = function() {
         private$ptr <- interp_create()
       },
       execute_text = function(script) {
         interp_execute_text(private$ptr, script)
       },
       set_variable = function(name, value) {
         if (is.numeric(value))
           interp_set_variable_numeric(private$ptr, name, value)
         else if (is.character(value))
           interp_set_variable_string(private$ptr, name, value)
       },
       get_variable = function(name) {
         interp_get_variable(private$ptr, name)
       }
     ),
     private = list(ptr = NULL)
   )
   ```

3. **Basic Test**:
   ```r
   script <- PraatScript$new()
   script$set_variable("x", 10)
   script$set_variable("y", 20)
   script$execute_text("z = x + y")
   result <- script$get_variable("z")
   stopifnot(result == 30)
   ```

**Deliverables**:
- ✅ Interpreter creation/destruction
- ✅ Variable get/set (numeric, string)
- ✅ Simple script execution (no objects)
- ✅ Basic unit tests

---

### Phase 2: Object Integration (3-4 weeks)

**Goal**: Create/access Praat objects from scripts, retrieve them as R6 objects

**Components**:
1. **Object Registry** (`src/interpreter_object_registry.cpp`):
   ```cpp
   // Global registry
   std::unordered_map<integer, SEXP> g_praat_object_xptrs;

   SEXP interp_get_selected_objects(SEXP interp_xptr) {
       // Get selected object IDs from Praat
       // Return list of XPtrs
   }

   void interp_register_object(SEXP interp_xptr, std::string name, SEXP object_xptr) {
       // Add R-created object to Praat's object list
   }
   ```

2. **R6 Extensions** (`R/praat-script.R`):
   ```r
   PraatScript <- R6Class("PraatScript",
     public = list(
       # ... Phase 1 methods ...

       register_object = function(name, r6_object) {
         if (!inherits(r6_object, "PraatObject"))
           stop("Must be a Praat object")
         interp_register_object(private$ptr, name, r6_object$get_ptr())
         private$registry[[name]] <- r6_object
       },

       get_selected_objects = function() {
         xptrs <- interp_get_selected_objects(private$ptr)
         lapply(xptrs, function(xptr) {
           # Determine type and wrap in appropriate R6 class
           class_name <- praat_object_get_class_name(xptr)
           switch(class_name,
             "Sound" = Sound$new(.xptr = xptr),
             "Pitch" = Pitch$new(.xptr = xptr),
             # ... etc
           )
         })
       },

       get_object_by_name = function(name) {
         xptr <- interp_get_object_by_name(private$ptr, name)
         # Wrap in R6 class
       }
     ),
     private = list(
       ptr = NULL,
       registry = NULL  # environment for registered objects
     )
   )
   ```

3. **Integration Test**:
   ```r
   script <- PraatScript$new()
   script$set_variable("file$", "test.wav")
   script$execute_text("
     sound = Read from file: file$
     pitch = To Pitch: 0.0, 75, 600
     mean_pitch = Get mean: 0, 0, 'Hertz'
   ")

   # Retrieve objects
   pitch <- script$get_object_by_name("pitch")
   stopifnot(inherits(pitch, "Pitch"))

   # Retrieve variable
   mean_pitch <- script$get_variable("mean_pitch")
   stopifnot(is.numeric(mean_pitch))
   ```

**Deliverables**:
- ✅ Object creation in scripts accessible from R
- ✅ R6 objects passable to scripts
- ✅ Automatic type detection and wrapping
- ✅ Object lifecycle management (prevent double-free)
- ✅ Integration tests with Sound, Pitch, Formant

---

### Phase 3: Advanced Features (2-3 weeks)

**Goal**: Support forms, procedures, file I/O, error handling

**Components**:
1. **Form Handling**:
   ```r
   script$execute_text("
     form Analyze sound
       sentence Sound_file test.wav
       real Pitch_floor 75
       real Pitch_ceiling 600
     endform
   ")
   script$set_form_value("Sound_file", "my_sound.wav")
   script$set_form_value("Pitch_floor", 100)
   script$continue_after_form()
   ```

2. **Procedure Calls**:
   ```r
   script$execute_text("
     procedure calculate_mean: pitch_object
       selectObject: pitch_object
       mean = Get mean: 0, 0, 'Hertz'
     endproc
   ")
   script$call_procedure("calculate_mean", pitch_id)
   result <- script$get_procedure_return()
   ```

3. **Error Handling**:
   ```r
   tryCatch({
     script$execute_text("invalid command")
   }, praat_script_error = function(e) {
     cat("Script error on line", e$line_number, ":", e$message, "\n")
   })
   ```

4. **File I/O Redirection**:
   ```r
   # Capture writeInfoLine output
   script$execute_text("
     writeInfoLine: 'Hello from Praat'
   ")
   output <- script$get_info_output()
   ```

**Deliverables**:
- ✅ Form parameter handling
- ✅ Procedure definition and calls
- ✅ Error handling with line numbers
- ✅ Info window output capture
- ✅ File I/O interception (optional)

---

### Phase 4: Batch Processing Integration (2 weeks)

**Goal**: Combine interpreter with batch processing utilities

**Components**:
1. **Batch Script Execution**:
   ```r
   batch_execute_script <- function(script_path, file_list, extract_vars = NULL) {
     script <- PraatScript$new()

     results <- lapply(file_list, function(file) {
       script$set_variable("current_file$", file)
       script$execute_file(script_path)

       if (!is.null(extract_vars)) {
         sapply(extract_vars, function(var) script$get_variable(var), simplify = FALSE)
       } else {
         NULL
       }
     })

     do.call(rbind, results)
   }
   ```

2. **Integration with Existing Utilities**:
   ```r
   # Combine with speaker's future batch processing
   process_directory(
     path = "sounds/",
     script = "analysis.praat",
     extract_variables = c("pitch_mean", "pitch_sd", "formant_1", "formant_2")
   )
   ```

**Deliverables**:
- ✅ Batch script execution over file lists
- ✅ Automatic variable extraction to data.frame
- ✅ Progress reporting
- ✅ Parallel execution support (future/furrr)

---

## Part 5: Technical Challenges & Solutions

### Challenge 1: Memory Management

**Problem**: Objects created in interpreter must not be double-freed

**Solution**:
- Use reference counting
- Maintain ownership map
- When object transferred from Praat to R, mark as "owned by R"
- Praat's `releaseToAmbiguousOwner()` already does this

### Challenge 2: Character Encoding

**Problem**: Praat uses UTF-32 (`char32`), R uses UTF-8

**Solution**:
- Use Melder's `Melder_peek8to32()` and `Melder_peek32to8()`
- Already used throughout speaker package

### Challenge 3: Object Selection State

**Problem**: Praat scripts use implicit selection ("selected Sound")

**Solution**:
- Maintain interpreter's selection state
- Expose `selectObject:`, `plusObject:`, `minusObject:`
- Provide `get_selected_objects()` method

### Challenge 4: Graphics/UI Dependencies

**Problem**: Praat scripts may call graphics functions (stubbed in speaker)

**Solution**:
- Continue using graphics stubs (`graphics_stubs_comprehensive.cpp`)
- Optionally provide warnings for unsupported graphics commands
- Document graphics limitations

### Challenge 5: Form Dialogs

**Problem**: Interactive forms require GUI

**Solution** (Two Options):
1. **Non-interactive mode**: Require form values set programmatically before execution
2. **R-based forms**: Use Shiny or tcltk to recreate form dialogs

Recommendation: Start with Option 1, add Option 2 later if needed

---

## Part 6: File Structure

### New Files to Create

```
R/
  praat-script.R                  # R6 PraatScript class
  praat-script-utils.R            # Batch processing helpers

src/
  interpreter_wrappers.cpp         # Core interpreter wrapping
  interpreter_object_registry.cpp  # Object lifetime management
  interpreter_variable_bridge.cpp  # Variable get/set
  interpreter_form_handling.cpp    # Form parameter handling
  interpreter_error_handling.cpp   # Error capture and reporting

inst/
  examples/
    interpreter_basic.R            # Basic usage examples
    interpreter_objects.R          # Object integration examples
    interpreter_batch.R            # Batch processing examples

tests/
  testthat/
    test-interpreter-basic.R
    test-interpreter-variables.R
    test-interpreter-objects.R
    test-interpreter-forms.R
    test-interpreter-procedures.R
    test-interpreter-batch.R
```

### Files to Modify

```
NAMESPACE                           # Export PraatScript class
DESCRIPTION                         # Update version, add dependencies
src/Makevars                        # Link interpreter-related files
R/praat-object.R                    # Add $get_ptr() method for object passing
```

---

## Part 7: API Design

### 7.1 Core API

```r
# Create interpreter
script <- PraatScript$new()

# Execute script from file
script$execute_file("analysis.praat")

# Execute script from text
script$execute_text("
  pitch_mean = 200
  pitch_sd = 50
")

# Evaluate single command
script$eval("writeInfoLine: 'Hello'")

# Variable access
script$set_variable("threshold", 0.5)
script$set_variable("filename$", "output.wav")
script$set_variable("formants#", c(800, 1200, 2500))
value <- script$get_variable("pitch_mean")

# Object management
script$register_object("my_sound", sound_r6_object)
selected <- script$get_selected_objects()  # Returns list of R6 objects
obj <- script$get_object_by_name("my_sound")
obj <- script$get_object_by_id(42)
objects <- script$list_objects()  # Returns data.frame of all objects

# Introspection
vars <- script$list_variables()  # Returns data.frame of variables
script$get_info_output()         # Get accumulated Info window text
script$clear_info()

# State management
script$reset()                    # Clear all variables and objects
script$get_line_number()          # Current line (during execution)
```

### 7.2 Batch Processing API

```r
# Process multiple files with same script
results <- batch_execute_script(
  script_path = "extract_pitch.praat",
  file_list = list.files("sounds/", pattern = "\\.wav$", full.names = TRUE),
  extract_variables = c("pitch_mean", "pitch_sd", "duration"),
  parallel = TRUE,
  progress = TRUE
)

# Process directory with Sound+TextGrid pairs
results <- process_paired_files(
  sound_dir = "sounds/",
  textgrid_dir = "textgrids/",
  script_path = "analyze_intervals.praat",
  extract_variables = c("formant_1", "formant_2", "vowel_label")
)
```

### 7.3 Advanced API

```r
# Form handling
script$execute_text("
  form Analysis parameters
    real Pitch_floor 75
    real Pitch_ceiling 600
    boolean Remove_noise 1
  endform
")
script$set_form_values(list(
  Pitch_floor = 100,
  Pitch_ceiling = 500,
  Remove_noise = TRUE
))
script$continue_after_form()

# Procedure calls
script$call_procedure("my_procedure", arg1, arg2)
return_value <- script$get_procedure_return_value()

# Error handling
script$set_error_handler(function(error, line_number, command) {
  cat("Error on line", line_number, ":", error$message, "\n")
  cat("Command:", command, "\n")
})

# Debugging
script$set_debug_mode(TRUE)
script$set_breakpoint(line_number = 42)
script$step()
script$continue()
```

---

## Part 8: Testing Strategy

### 8.1 Unit Tests (testthat)

```r
test_that("interpreter executes basic arithmetic", {
  script <- PraatScript$new()
  script$set_variable("x", 10)
  script$set_variable("y", 20)
  script$execute_text("z = x + y")
  expect_equal(script$get_variable("z"), 30)
})

test_that("interpreter creates and retrieves Sound objects", {
  script <- PraatScript$new()
  script$execute_text("
    sound = Create Sound from formula: 'test', 1, 0, 1, 44100, '0.5 * sin(2*pi*440*x)'
  ")
  objects <- script$list_objects()
  expect_equal(nrow(objects), 1)
  expect_equal(objects$class[1], "Sound")

  sound <- script$get_object_by_name("test")
  expect_s3_class(sound, "Sound")
  expect_equal(sound$get_duration(), 1.0, tolerance = 0.01)
})

test_that("interpreter handles errors gracefully", {
  script <- PraatScript$new()
  expect_error(
    script$execute_text("invalid praat command"),
    regexp = "Unknown command"
  )
})
```

### 8.2 Integration Tests

```r
test_that("full analysis workflow", {
  script <- PraatScript$new()

  # Create test sound
  sound <- Sound$create_tone(duration = 1.0, frequency = 440)
  script$register_object("test_sound", sound)

  # Run analysis
  script$execute_text("
    selectObject: 'test_sound'
    pitch = To Pitch: 0.0, 75, 600
    mean_pitch = Get mean: 0, 0, 'Hertz'
    sd_pitch = Get standard deviation: 0, 0, 'Hertz'
  ")

  # Check results
  mean_pitch <- script$get_variable("mean_pitch")
  expect_equal(mean_pitch, 440, tolerance = 5)

  # Retrieve pitch object
  pitch <- script$get_object_by_name("pitch")
  expect_s3_class(pitch, "Pitch")
})
```

### 8.3 Benchmark Tests

Compare performance of:
1. Pure R6 speaker API
2. Interpreter executing equivalent script
3. Command-line Praat (baseline)

---

## Part 9: Documentation

### 9.1 Vignettes

```r
# vignettes/interpreter-introduction.Rmd
vignette("interpreter-introduction", package = "speaker")

# vignettes/interpreter-objects.Rmd
vignette("interpreter-objects", package = "speaker")

# vignettes/interpreter-batch-processing.Rmd
vignette("interpreter-batch-processing", package = "speaker")

# vignettes/migrating-from-praat-scripts.Rmd
vignette("migrating-from-praat-scripts", package = "speaker")
```

### 9.2 README Examples

```r
# Basic usage
library(speaker)

script <- PraatScript$new()
script$set_variable("frequency", 440)
script$execute_text("
  sound = Create Sound from formula: 'tone', 1, 0, 1, 44100, 'sin(2*pi*frequency*x)'
  pitch = To Pitch: 0.0, 75, 600
  mean_pitch = Get mean: 0, 0, 'Hertz'
")
cat("Mean pitch:", script$get_variable("mean_pitch"), "Hz\n")
```

---

## Part 10: Implementation Timeline

### Roadmap (Total: 9-12 weeks)

| **Phase** | **Duration** | **Deliverables** |
|-----------|--------------|------------------|
| Phase 1: MVP | 2-3 weeks | Basic interpreter, variable get/set, simple scripts |
| Phase 2: Objects | 3-4 weeks | Object integration, lifecycle management, R6 wrapping |
| Phase 3: Advanced | 2-3 weeks | Forms, procedures, error handling, Info output |
| Phase 4: Batch | 2 weeks | Batch processing, directory operations, parallel execution |

### Weekly Breakdown (Example for Phase 1)

**Week 1: C++ Foundation**
- Day 1-2: Create `interpreter_wrappers.cpp`, basic XPtr wrapping
- Day 3-4: Implement variable get/set for numeric and string
- Day 5: Script execution from text
- Day 6-7: Testing and debugging

**Week 2: R6 Interface**
- Day 1-2: Create `PraatScript` R6 class
- Day 3-4: Method implementations
- Day 5: Unit tests
- Day 6-7: Documentation and examples

**Week 3: Polish and Test**
- Day 1-3: Integration testing
- Day 4-5: Error handling improvements
- Day 6-7: Documentation, vignettes

---

## Part 11: Risks and Mitigation

### Risk 1: Praat Interpreter Depends on GUI/Graphics
**Mitigation**: Already handled via graphics stubs. Continue this pattern.

### Risk 2: Memory Leaks from Object Lifecycle Mismanagement
**Mitigation**:
- Extensive testing with valgrind
- Use Rcpp's automatic memory management where possible
- Clear ownership rules in object registry

### Risk 3: Praat Updates Break Interpreter Integration
**Mitigation**:
- Pin Praat version in speaker package
- Abstract interpreter interface
- Version-specific compatibility layer if needed

### Risk 4: Performance Overhead from R↔C++ Transitions
**Mitigation**:
- Benchmark and profile
- Minimize boundary crossings
- Batch operations where possible

---

## Part 12: Alternative Approaches Considered

### Alternative 1: Pure R Parser (Rejected)
**Pros**: No C++ dependencies, easier to debug
**Cons**: Massive effort, wouldn't support formulas, 1000+ lines of lexer/parser code

### Alternative 2: Transpile Praat→R (Rejected)
**Pros**: Could optimize for R idioms
**Cons**: Incomplete coverage, complex corner cases, formula evaluation still needs Praat

### Alternative 3: Call Praat Executable (Rejected)
**Pros**: No integration needed
**Cons**: Slow (process spawning), no object sharing, brittle file I/O

### Chosen: Wrap Praat's Interpreter (Recommended)
**Pros**:
- Leverage 30+ years of tested code
- Full Praat compatibility
- Access to internal Formula evaluator
- Reuse existing speaker infrastructure

**Cons**:
- C++ complexity
- Some limitations (graphics, UI)

---

## Conclusion

Implementing a Praat script interpreter in the speaker package is **technically feasible** and **architecturally sound**. The existing infrastructure (R6 classes, external pointers, Rcpp wrappers) provides an excellent foundation.

### Key Success Factors:
1. ✅ Speaker already wraps Praat C++ objects successfully
2. ✅ Praat's `Interpreter` class is well-defined and usable
3. ✅ Memory management patterns are established
4. ✅ Gradual phased implementation reduces risk

### Recommended Next Steps:
1. **Prototype Phase 1** (1 week) to validate approach
2. **Review with package maintainer** before full implementation
3. **Proceed with full Phase 1-4 implementation** (9-12 weeks)
4. **Beta testing with real Praat scripts** from the analyzed archive
5. **Release as experimental feature** with clear documentation of limitations

### Expected Outcome:
A powerful hybrid approach where users can:
- Write R code using speaker's R6 API (better IDE support, type safety)
- Execute existing Praat scripts without modification (backward compatibility)
- Mix both approaches as needed (gradual migration path)

This will make speaker the **most complete and flexible R package for Praat functionality**.
