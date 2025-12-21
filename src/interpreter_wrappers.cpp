// interpreter_wrappers.cpp
// Rcpp wrappers for Praat Interpreter functionality

#include <Rcpp.h>
#include "praat_types.h"
#include "praat_xptr_utils.h"
#include "praat_error_handling.h"

// Praat headers
#include "sys/Interpreter.h"
#include "sys/praat.h"
#include "sys/praat_script.h"
#include "melder/melder.h"
#include "praat.github.io/fon/praat_uvafon_init.h"

using namespace Rcpp;

// ==============================================================================
// Initialization
// ==============================================================================

static bool praat_interpreter_initialized = false;

// [[Rcpp::export(.praat_interpreter_init)]]
void praat_interpreter_init() {
    if (!praat_interpreter_initialized) {
        try {
            // Initialize Praat library
            praatlib_init();
            
            // Register all Praat object classes and commands
            praat_uvafon_init();
            
            praat_interpreter_initialized = true;
        } catch (MelderError) {
            Melder_clearError();
            stop("Failed to initialize Praat interpreter");
        }
    }
}

// [[Rcpp::export(.praat_is_initialized)]]
bool praat_is_initialized() {
    return praat_interpreter_initialized;
}

// ==============================================================================
// Simple Script Execution
// ==============================================================================

// [[Rcpp::export(.praat_run_script)]]
void praat_run_script(std::string script_text) {
    // Auto-initialize if needed
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        // Execute script using Praat's built-in function
        praatlib_executeScript(script_text.c_str());
    } catch (MelderError) {
        // Convert Praat error to R error
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// ==============================================================================
// Expression Evaluation
// ==============================================================================

// [[Rcpp::export(.praat_evaluate_numeric)]]
double praat_evaluate_numeric(std::string expression) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        double value;
        Interpreter_numericExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &value);
        return value;
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_evaluate_string)]]
std::string praat_evaluate_string(std::string expression) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        autostring32 result = Interpreter_stringExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()));
        return Melder_peek32to8(result.get());
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_evaluate_vector)]]
NumericVector praat_evaluate_vector(std::string expression) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        VEC vec;
        bool owned;
        Interpreter_numericVectorExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &vec, &owned);
        
        // Copy to R vector
        NumericVector result(vec.size);
        for (integer i = 1; i <= vec.size; i++) {
            result[i-1] = vec[i];
        }
        
        // Note: vec is automatically freed by autoInterpreter destructor
        
        return result;
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// ==============================================================================
// Persistent Interpreter
// ==============================================================================

// [[Rcpp::export(.praat_interpreter_create)]]
SEXP praat_interpreter_create() {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        return create_xptr_from_auto<structInterpreter>(interpreter);
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_interpreter_run)]]
void praat_interpreter_run(SEXP xptr, std::string script) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        autostring32 text = Melder_8to32(script.c_str());
        Interpreter_run(interpreter.get(), text.get(), true);  // true = reuse variables
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_interpreter_get_variable)]]
SEXP praat_interpreter_get_variable(SEXP xptr, std::string name) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        autostring32 key = Melder_8to32(name.c_str());
        InterpreterVariable var = Interpreter_hasVariable(interpreter.get(), key.get());
        
        if (!var) {
            return R_NilValue;
        }
        
        // Determine type from variable name suffix
        if (Melder_endsWith(key.get(), U"$")) {
            // String variable
            return wrap(Melder_peek32to8(var->stringValue.get()));
        } else if (Melder_endsWith(key.get(), U"#")) {
            // Vector variable
            VEC vec = var->numericVectorValue.get();
            NumericVector result(vec.size);
            for (integer i = 1; i <= vec.size; i++) {
                result[i-1] = vec[i];
            }
            return result;
        } else if (Melder_endsWith(key.get(), U"##")) {
            // Matrix variable
            MAT mat = var->numericMatrixValue.get();
            NumericMatrix result(mat.nrow, mat.ncol);
            for (integer i = 1; i <= mat.nrow; i++) {
                for (integer j = 1; j <= mat.ncol; j++) {
                    result(i-1, j-1) = mat[i][j];
                }
            }
            return result;
        } else {
            // Numeric variable
            return wrap(var->numericValue);
        }
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}
