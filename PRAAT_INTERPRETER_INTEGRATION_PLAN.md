# Praat Interpreter Integration Plan for pladdrr

## Executive Summary

This plan outlines how to expose the Praat script interpreter in the R package by directly calling the embedded Praat C++ codebase in `src/praat.github.io/`. The interpreter is a **production-quality script execution system** (~15,783 lines) that can be exposed with moderate effort.

## Architecture Overview

```
R User Code
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ R Interface Layer (R6 Classes + Rcpp)                               │
│  praat_run_script()     - Execute script text                       │
│  praat_execute_command() - Execute single command                   │
│  praat_evaluate()       - Evaluate formula expression               │
│  PraatInterpreter$new() - Persistent interpreter with state         │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ C++ Wrapper Layer (src/interpreter_wrappers.cpp)                    │
│  - praatlib_init() initialization                                   │
│  - Interpreter_run() script execution                               │
│  - praat_executeCommand() single command dispatch                   │
│  - Object ↔ XPtr conversion                                         │
│  - Error handling (MelderError → Rcpp::stop)                        │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Praat Interpreter (sys/Interpreter.cpp + sys/Formula.cpp)           │
│  - Script parsing and execution (~3,558 lines)                      │
│  - Formula evaluation (~9,451 lines)                                │
│  - Variable management (hash map)                                   │
│  - Control flow (if/for/while/procedure)                            │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Command Registry (sys/praat_actions.cpp + praat_menuCommands.cpp)   │
│  - Action commands (selected object operations)                     │
│  - Menu commands (general operations)                               │
│  - Callbacks to object creation/manipulation                        │
└─────────────────────────────────────────────────────────────────────┘
    │
    ▼
┌─────────────────────────────────────────────────────────────────────┐
│ Praat Objects (fon/*.cpp) - Already integrated!                     │
│  Sound, Pitch, Formant, Spectrum, TextGrid, etc.                    │
└─────────────────────────────────────────────────────────────────────┘
```

## Key Entry Points (Already Exist in Praat Source)

### 1. `praatlib_init()` - Library Initialization
**Location**: `src/praat.github.io/sys/praat.cpp:1070-1089`
```cpp
extern "C" void praatlib_init () {
    setThePraatLocale ();
    Melder_init ();
    Melder_rememberShellDirectory ();
    Melder_batch = true;
    theCurrentPraatApplication -> batch = true;
    Thing_recognizeClassesByName (classCollection, classStrings, ...);
    praat_addMenus (nullptr);      // Register menu commands
    praat_addFixedButtons (nullptr); // Register fixed buttons
    praat_addMenus2 ();
}
```

### 2. `praatlib_executeScript()` - Execute Script Text
**Location**: `src/praat.github.io/sys/praat_script.cpp:677-685`
```cpp
extern "C" void praatlib_executeScript (const char *text8) {
    autoInterpreter interpreter = Interpreter_create ();
    autostring32 string = Melder_8to32 (text8);
    Interpreter_run (interpreter.get(), string.get(), false);
}
```

### 3. `praat_executeCommand()` - Execute Single Command
**Location**: `src/praat.github.io/sys/praat_script.cpp:182-502`
```cpp
bool praat_executeCommand (Interpreter interpreter, char32 *command);
```

### 4. Expression Evaluation Functions
**Location**: `src/praat.github.io/sys/Interpreter.h:205-211`
```cpp
void Interpreter_numericExpression (Interpreter me, conststring32 expression, double *p_value);
autostring32 Interpreter_stringExpression (Interpreter me, conststring32 expression);
void Interpreter_numericVectorExpression (Interpreter me, conststring32 expression, VEC *p_value, bool *p_owned);
void Interpreter_numericMatrixExpression (Interpreter me, conststring32 expression, MAT *p_value, bool *p_owned);
```

## Implementation Phases

### Phase 1: Foundation (1-2 weeks)

#### 1.1 Create Initialization Wrapper
```cpp
// src/praat_interpreter_init.cpp

#include <Rcpp.h>
#include "praatP.h"
#include "praat.h"

static bool praat_initialized = false;

// [[Rcpp::export(.praat_interpreter_init)]]
void praat_interpreter_init() {
    if (!praat_initialized) {
        praatlib_init();

        // Register fon module commands (Sound, Pitch, etc.)
        praat_uvafon_init();  // Already available from existing integration

        praat_initialized = true;
    }
}

// [[Rcpp::export(.praat_is_initialized)]]
bool praat_is_initialized() {
    return praat_initialized;
}
```

#### 1.2 Create Simple Script Execution Wrapper
```cpp
// src/praat_interpreter_wrappers.cpp

#include <Rcpp.h>
#include "Interpreter.h"
#include "praat_script.h"

// [[Rcpp::export(.praat_run_script)]]
void praat_run_script(std::string script_text) {
    if (!praat_is_initialized()) {
        praat_interpreter_init();
    }

    try {
        praatlib_executeScript(script_text.c_str());
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(error_msg);
    }
}
```

#### 1.3 Create R Interface
```r
# R/praat-interpreter.R

#' Execute a Praat script
#'
#' @param script Character string containing Praat script code
#' @return Invisibly returns NULL. Side effects: creates objects in Praat's object list
#' @export
praat_run_script <- function(script) {
    .praat_run_script(script)
    invisible(NULL)
}

#' Evaluate a Praat expression
#'
#' @param expression Character string containing a Praat formula
#' @return The result of the expression evaluation
#' @export
praat_eval <- function(expression) {
    .praat_evaluate_expression(expression)
}
```

### Phase 2: Object Bridge (2-3 weeks)

The critical challenge: **bridging Praat's internal object list with R6 objects**.

#### 2.1 Object List Access
```cpp
// Need to expose the theCurrentPraatObjects list

// [[Rcpp::export(.praat_get_selected_objects)]]
Rcpp::List praat_get_selected_objects() {
    Rcpp::List result;
    integer IOBJECT;
    WHERE (SELECTED) {
        Daata object = (Daata) OBJECT;
        std::string name = Melder_peek32to8(object->name.get());
        std::string type = Thing_className(OBJECT);
        integer id = ID;
        result.push_back(Rcpp::List::create(
            Rcpp::Named("id") = id,
            Rcpp::Named("type") = type,
            Rcpp::Named("name") = name
        ));
    }
    return result;
}

// [[Rcpp::export(.praat_get_object_by_id)]]
SEXP praat_get_object_by_id(int id) {
    integer IOBJECT;
    WHERE (ID == id) {
        // Convert to appropriate XPtr based on type
        if (Thing_isa(OBJECT, classSound)) {
            structSound* sound = (structSound*) OBJECT;
            return Rcpp::XPtr<structSound>(sound, false); // false = don't register finalizer (owned by Praat)
        }
        // ... similar for other types
    }
    Rcpp::stop("Object not found");
}
```

#### 2.2 Bidirectional Object Transfer

```cpp
// Add R6 object to Praat's list
// [[Rcpp::export(.praat_add_object)]]
int praat_add_object_from_xptr(SEXP xptr, std::string name, std::string type) {
    if (type == "Sound") {
        Rcpp::XPtr<structSound> sound(xptr);
        // Create a copy for Praat to own
        autoSound copy = Sound_copy(sound.get());
        praat_new(copy.move(), Melder_peek8to32(name.c_str()));
        praat_updateSelection();
        // Return the ID of the new object
        return ID;  // Most recently added object
    }
    // ... similar for other types
    Rcpp::stop("Unknown object type");
}
```

### Phase 3: Expression Evaluation (1 week)

```cpp
// [[Rcpp::export(.praat_evaluate_numeric)]]
double praat_evaluate_numeric(std::string expression) {
    autoInterpreter interpreter = Interpreter_create();
    double value;
    try {
        Interpreter_numericExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &value);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(error_msg);
    }
    return value;
}

// [[Rcpp::export(.praat_evaluate_string)]]
std::string praat_evaluate_string(std::string expression) {
    autoInterpreter interpreter = Interpreter_create();
    try {
        autostring32 result = Interpreter_stringExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()));
        return Melder_peek32to8(result.get());
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(error_msg);
    }
}

// [[Rcpp::export(.praat_evaluate_vector)]]
Rcpp::NumericVector praat_evaluate_vector(std::string expression) {
    autoInterpreter interpreter = Interpreter_create();
    VEC vec;
    bool owned;
    try {
        Interpreter_numericVectorExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &vec, &owned);
        Rcpp::NumericVector result(vec.size);
        for (integer i = 1; i <= vec.size; i++) {
            result[i-1] = vec[i];
        }
        if (owned) {
            // Free the vector if we own it
        }
        return result;
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(error_msg);
    }
}
```

### Phase 4: Persistent Interpreter with Variables (1-2 weeks)

```cpp
// [[Rcpp::export(.praat_interpreter_create)]]
SEXP praat_interpreter_create() {
    autoInterpreter interpreter = Interpreter_create();
    Interpreter* ptr = interpreter.releaseToAmbiguousOwner();
    return Rcpp::XPtr<Interpreter>(ptr, true);
}

// [[Rcpp::export(.praat_interpreter_run)]]
void praat_interpreter_run(SEXP xptr, std::string script, bool reuse_variables) {
    Rcpp::XPtr<Interpreter> interpreter(xptr);
    autostring32 text = Melder_8to32(script.c_str());
    try {
        Interpreter_run(interpreter.get(), text.get(), reuse_variables);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        Rcpp::stop(error_msg);
    }
}

// [[Rcpp::export(.praat_interpreter_get_variable)]]
SEXP praat_interpreter_get_variable(SEXP xptr, std::string name) {
    Rcpp::XPtr<Interpreter> interpreter(xptr);
    autostring32 key = Melder_8to32(name.c_str());
    InterpreterVariable var = Interpreter_hasVariable(interpreter.get(), key.get());

    if (!var) {
        return R_NilValue;
    }

    // Determine type from variable name suffix
    if (Melder_endsWith(key.get(), U"$")) {
        // String variable
        return Rcpp::wrap(Melder_peek32to8(var->stringValue.get()));
    } else if (Melder_endsWith(key.get(), U"#")) {
        // Vector variable
        VEC vec = var->numericVectorValue.get();
        Rcpp::NumericVector result(vec.size);
        for (integer i = 1; i <= vec.size; i++) {
            result[i-1] = vec[i];
        }
        return result;
    } else if (Melder_endsWith(key.get(), U"##")) {
        // Matrix variable
        MAT mat = var->numericMatrixValue.get();
        Rcpp::NumericMatrix result(mat.nrow, mat.ncol);
        for (integer i = 1; i <= mat.nrow; i++) {
            for (integer j = 1; j <= mat.ncol; j++) {
                result(i-1, j-1) = mat[i][j];
            }
        }
        return result;
    } else {
        // Numeric variable
        return Rcpp::wrap(var->numericValue);
    }
}
```

### Phase 5: R6 Wrapper Class (1 week)

```r
# R/praat-interpreter-r6.R

#' Praat Script Interpreter
#'
#' R6 class for executing Praat scripts with persistent state.
#'
#' @export
PraatInterpreter <- R6::R6Class(
  "PraatInterpreter",

  public = list(
    #' @description Create new interpreter instance
    initialize = function() {
      private$ptr <- .praat_interpreter_create()
    },

    #' @description Execute Praat script code
    #' @param script Character string with Praat script
    #' @param reuse_variables Logical; if TRUE, keep variables from previous runs
    run = function(script, reuse_variables = TRUE) {
      .praat_interpreter_run(private$ptr, script, reuse_variables)
      invisible(self)
    },

    #' @description Get variable value from interpreter
    #' @param name Variable name (include suffix: x, x$, x#, x##)
    get_variable = function(name) {
      .praat_interpreter_get_variable(private$ptr, name)
    },

    #' @description Set variable in interpreter
    #' @param name Variable name
    #' @param value Value to set
    set_variable = function(name, value) {
      .praat_interpreter_set_variable(private$ptr, name, value)
      invisible(self)
    },

    #' @description Get all objects created during script execution
    get_objects = function() {
      .praat_get_all_objects()
    },

    #' @description Get selected objects
    get_selected = function() {
      .praat_get_selected_objects()
    },

    #' @description Select an object by ID
    #' @param id Object ID
    select = function(id) {
      .praat_select_object(id)
      invisible(self)
    },

    #' @description Convert Praat object to R6 wrapper
    #' @param id Object ID
    to_r6 = function(id) {
      .praat_object_to_r6(id)
    }
  ),

  private = list(
    ptr = NULL
  )
)
```

## Stubs Required

The following functions may need stubs (no-ops or minimal implementations) if not already present:

### Already Stubbed (in pladdrr)
- Graphics system (`Graphics_*`) - for picture drawing
- GUI system (`Gui*`) - for dialogs
- Editors (`Editor*`) - for interactive windows

### May Need Additional Stubs
```cpp
// File I/O stubs (if not using file operations)
void MelderFile_appendText (MelderFile file, conststring32 text) { /* no-op */ }

// Demo window stubs (used by some scripts)
void Demo_open() { /* no-op */ }
void Demo_close() { /* no-op */ }

// Pause dialog stubs (interactive scripts)
void UiPause_begin(...) { Melder_throw(U"pause not supported in library mode"); }
```

## Command Registration

The Praat command system requires initialization. Key init functions:

```cpp
// These are called during praatlib_init()
void praat_addMenus (GuiWindow window);      // General menu commands
void praat_addFixedButtons (GuiWindow window); // Fixed button commands
void praat_addMenus2 ();                      // Additional menus

// These must be called for phonetic objects
void praat_uvafon_init ();  // Sound, Pitch, Formant, etc.
// Already used in pladdrr via fon/ integration
```

## Usage Examples

### Simple Script Execution
```r
# Execute a simple Praat script
praat_run_script('
  Create Sound from formula: "sineWave", 1, 0, 1, 44100, "0.5 * sin(2*pi*440*x)"
  pitch = To Pitch: 0.0, 75, 600
')

# Get the objects created
objects <- praat_get_selected_objects()
```

### Persistent Interpreter with Variables
```r
# Create interpreter instance
interp <- PraatInterpreter$new()

# Run script with variable assignment
interp$run('
  sound = Create Sound from formula: "test", 1, 0, 1, 44100, "0.5*sin(2*pi*440*x)"
  duration = Get duration
  mean_intensity = Get mean... 0 0
')

# Access variables in R
duration <- interp$get_variable("duration")
mean_intensity <- interp$get_variable("mean_intensity")

# Get the Sound object as R6
sound_id <- interp$get_selected()[[1]]$id
sound <- interp$to_r6(sound_id)  # Returns Sound R6 object
```

### Hybrid Workflow
```r
# Create Sound in R
sound <- Sound$new("audio.wav")

# Add to Praat's object list for script processing
praat_add_object(sound, "mySound")

# Run Praat script that operates on it
praat_run_script('
  selectObject: "Sound mySound"
  pitch = To Pitch: 0.0, 75, 600
  meanF0 = Get mean: 0, 0, "Hertz"
')

# Get result back
mean_f0 <- praat_get_variable("meanF0")
```

## Timeline Estimate

| Phase | Description | Duration |
|-------|-------------|----------|
| **Phase 1** | Foundation (init, simple script execution) | 1-2 weeks |
| **Phase 2** | Object Bridge (R6 ↔ Praat objects) | 2-3 weeks |
| **Phase 3** | Expression Evaluation | 1 week |
| **Phase 4** | Persistent Interpreter | 1-2 weeks |
| **Phase 5** | R6 Wrapper & Polish | 1 week |
| **Testing & Docs** | Comprehensive testing, documentation | 2 weeks |
| **TOTAL** | | **8-11 weeks** |

## Risks and Mitigations

| Risk | Mitigation |
|------|------------|
| Memory management conflicts between R GC and Praat | Use ownership flags on XPtr; careful about who owns objects |
| Thread safety issues | Document single-threaded usage; add mutex if needed |
| Incomplete command registration | Test incrementally with specific command sets |
| Error message propagation | Consistent MelderError → Rcpp::stop pattern |
| Variable scope edge cases | Comprehensive test suite for complex scripts |

## Success Criteria

1. **Basic Scripts Work**: Simple Praat scripts execute without errors
2. **Object Round-Trip**: Objects can be created in R, processed by Praat script, returned to R
3. **Variable Access**: All variable types (numeric, string, vector, matrix) accessible from R
4. **Error Handling**: Praat errors translate to informative R errors
5. **Performance**: Minimal overhead compared to pure R6 method calls
6. **Documentation**: Clear examples for hybrid workflows

## Files to Create/Modify

### New Files
- `src/interpreter_init.cpp` - Initialization functions
- `src/interpreter_wrappers.cpp` - Script execution wrappers
- `src/interpreter_objects.cpp` - Object bridge functions
- `R/praat-interpreter.R` - High-level R functions
- `R/praat-interpreter-r6.R` - PraatInterpreter R6 class
- `tests/testthat/test-interpreter.R` - Test suite

### Modify
- `src/Makevars` - Add new source files
- `NAMESPACE` - Export new functions
- `DESCRIPTION` - Version bump

## Appendix: Key Praat Source Files

| File | Lines | Purpose |
|------|-------|---------|
| `sys/Interpreter.h` | 218 | Class definition |
| `sys/Interpreter.cpp` | 3,558 | Script execution |
| `sys/Formula.cpp` | 9,451 | Expression evaluation |
| `sys/praat_script.cpp` | 791 | Script loading/dispatch |
| `sys/praat_actions.cpp` | 950 | Action command registry |
| `sys/praat_menuCommands.cpp` | 620 | Menu command registry |
| `sys/praat.cpp` | ~2,000 | Main praat functions |
| `sys/praatP.h` | ~200 | Internal declarations |

---

**Document Version**: 1.0
**Created**: 2025-12-20
**Author**: Claude (Opus 4.5)
