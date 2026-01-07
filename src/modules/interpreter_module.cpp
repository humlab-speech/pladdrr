// interpreter_module.cpp
// Rcpp Module exposing Praat Interpreter functionality

#include <Rcpp.h>
#include "module_common.h"

// Praat headers (use -I paths from Makevars)
#include "praat.github.io/sys/Interpreter.h"
#include "praat.github.io/sys/praat.h"
#include "praat.github.io/sys/praat_script.h"
#include "praat.github.io/melder/melder.h"
#include "praat.github.io/melder/melder_info.h"
#include "praat.github.io/fon/praat_uvafon_init.h"

using namespace Rcpp;

// =============================================================================
// Module-local initialization (mirrors interpreter_wrappers.cpp)
// =============================================================================

static bool s_interpreter_initialized = false;

static void ensure_interpreter_initialized() {
    if (!s_interpreter_initialized) {
        try {
            // Initialize Praat library (registers classes and commands)
            praatlib_init();
            praat_uvafon_init();
            s_interpreter_initialized = true;
        } catch (MelderError) {
            Melder_clearError();
            Rcpp::stop("Failed to initialize Praat interpreter subsystem");
        }
    }
}

// Helper to add predefined boolean constants to interpreter
static void addPredefinedVariables(Interpreter interpreter) {
    // Add yes/no as predefined boolean constants for colon-syntax arguments
    InterpreterVariable yes_var = Interpreter_lookUpVariable(interpreter, U"yes");
    yes_var->numericValue = 1.0;

    InterpreterVariable no_var = Interpreter_lookUpVariable(interpreter, U"no");
    no_var->numericValue = 0.0;

    // Also add true/false for consistency
    InterpreterVariable true_var = Interpreter_lookUpVariable(interpreter, U"true");
    true_var->numericValue = 1.0;

    InterpreterVariable false_var = Interpreter_lookUpVariable(interpreter, U"false");
    false_var->numericValue = 0.0;
}

// =============================================================================
// RInterpreter Class - Wraps Interpreter XPtr with methods
// =============================================================================

class RInterpreter {
private:
    // Helper to create XPtr - used in constructor initializer list
    static XPtr<structInterpreter> make_interpreter() {
        ensure_interpreter_initialized();

        try {
            autoInterpreter interpreter = Interpreter_create();
            addPredefinedVariables(interpreter.get());
            return create_xptr_from_auto<structInterpreter>(interpreter);
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop("Failed to create interpreter: " + error_msg);
        }
        return XPtr<structInterpreter>(R_NilValue);  // Never reached
    }

public:
    XPtr<structInterpreter> ptr;

    // Default constructor - creates a valid interpreter
    RInterpreter() : ptr(make_interpreter()) {}

    // Constructor from XPtr (for wrapping existing interpreter)
    RInterpreter(XPtr<structInterpreter> p) : ptr(p) {}

    // =========================================================================
    // Validation
    // =========================================================================

    bool is_valid() {
        return ptr.get() != nullptr;
    }

    // =========================================================================
    // Script Execution
    // =========================================================================

    void run(std::string script) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            autostring32 text = Melder_8to32(script.c_str());
            Interpreter_run(ptr.get(), text.get(), true);  // true = reuse variables
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    // =========================================================================
    // Expression Evaluation
    // =========================================================================

    double eval_numeric(std::string expression) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            double result;
            Interpreter_numericExpression(ptr.get(),
                Melder_peek8to32(expression.c_str()), &result);
            return result;
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    std::string eval_string(std::string expression) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            autostring32 result = Interpreter_stringExpression(ptr.get(),
                Melder_peek8to32(expression.c_str()));
            return Melder_peek32to8(result.get());
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    NumericVector eval_vector(std::string expression) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            VEC vec;
            bool owned;
            Interpreter_numericVectorExpression(ptr.get(),
                Melder_peek8to32(expression.c_str()), &vec, &owned);
            
            // Copy to R numeric vector
            NumericVector result(vec.size);
            for (integer i = 1; i <= vec.size; i++) {
                result[i-1] = vec[i];
            }
            
            return result;
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    NumericMatrix eval_matrix(std::string expression) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            MAT mat;
            bool owned;
            Interpreter_numericMatrixExpression(ptr.get(),
                Melder_peek8to32(expression.c_str()), &mat, &owned);
            
            // Copy to R numeric matrix (column-major order)
            NumericMatrix result(mat.nrow, mat.ncol);
            for (integer i = 1; i <= mat.nrow; i++) {
                for (integer j = 1; j <= mat.ncol; j++) {
                    result(i-1, j-1) = mat[i][j];  // 1-based -> 0-based
                }
            }
            
            return result;
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    CharacterVector eval_string_array(std::string expression) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            STRVEC strvec;
            bool owned;
            Interpreter_stringArrayExpression(ptr.get(),
                Melder_peek8to32(expression.c_str()), &strvec, &owned);
            
            // Copy to R character vector
            CharacterVector result(strvec.size);
            for (integer i = 1; i <= strvec.size; i++) {
                result[i-1] = Melder_peek32to8(strvec[i]);
            }
            
            return result;
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    // =========================================================================
    // Variable Management
    // =========================================================================

    SEXP get_variable(std::string name) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            autostring32 key = Melder_8to32(name.c_str());
            InterpreterVariable var = Interpreter_hasVariable(ptr.get(), key.get());
            
            if (!var) {
                return R_NilValue;
            }
            
            // Determine type from variable name suffix
            if (Melder_endsWith(key.get(), U"$#")) {
                // String array variable (must check before single $)
                STRVEC strvec = var->stringArrayValue.get();
                CharacterVector result(strvec.size);
                for (integer i = 1; i <= strvec.size; i++) {
                    result[i-1] = Melder_peek32to8(strvec[i]);
                }
                return result;
            } else if (Melder_endsWith(key.get(), U"##")) {
                // Matrix variable (must check before single #)
                MAT mat = var->numericMatrixValue.get();
                NumericMatrix result(mat.nrow, mat.ncol);
                for (integer i = 1; i <= mat.nrow; i++) {
                    for (integer j = 1; j <= mat.ncol; j++) {
                        result(i-1, j-1) = mat[i][j];
                    }
                }
                return result;
            } else if (Melder_endsWith(key.get(), U"$")) {
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

    void set_variable(std::string name, SEXP value) {
        VALIDATE_PTR(ptr, Interpreter);
        
        try {
            // Check matrix FIRST (before length checks), since 1x1 matrices have length 1
            if (Rf_isMatrix(value) && (Rf_isReal(value) || Rf_isInteger(value))) {
                // Matrix - add ## suffix if needed
                conststring32 tempName = Melder_peek8to32(name.c_str());
                conststring32 varNameRaw;
                if (Melder_endsWith(tempName, U"##")) {
                    varNameRaw = tempName;
                } else {
                    varNameRaw = Melder_cat(tempName, U"##");
                }
                NumericMatrix mat(value);
                InterpreterVariable var = Interpreter_lookUpVariable(ptr.get(), varNameRaw);
                // Create temporary MAT and copy data
                autoMAT temp = raw_MAT(mat.nrow(), mat.ncol());
                for (int i = 0; i < mat.nrow(); i++) {
                    for (int j = 0; j < mat.ncol(); j++) {
                        temp[i+1][j+1] = mat(i, j);  // 0-based -> 1-based
                    }
                }
                var->numericMatrixValue = temp.move();
                
            } else if ((Rf_isReal(value) || Rf_isInteger(value)) && Rf_length(value) == 1) {
                // Numeric scalar - use name as-is (no suffix)
                autostring32 varName = Melder_8to32(name.c_str());
                double val = Rf_asReal(value);
                InterpreterVariable var = Interpreter_lookUpVariable(ptr.get(), varName.get());
                var->numericValue = val;
                
            } else if (Rf_isString(value) && Rf_length(value) > 1) {
                // String array - add $# suffix if needed
                conststring32 tempName = Melder_peek8to32(name.c_str());
                conststring32 varNameRaw;
                if (Melder_endsWith(tempName, U"$#")) {
                    varNameRaw = tempName;
                } else {
                    varNameRaw = Melder_cat(tempName, U"$#");
                }
                CharacterVector strvec(value);
                InterpreterVariable var = Interpreter_lookUpVariable(ptr.get(), varNameRaw);
                // Create temporary STRVEC and copy data
                autoSTRVEC temp (strvec.length());
                for (int i = 0; i < strvec.length(); i++) {
                    temp[i+1] = Melder_dup_f(Melder_peek8to32(CHAR(STRING_ELT(value, i))));
                }
                var->stringArrayValue = temp.move();
                
            } else if (Rf_isString(value) && Rf_length(value) == 1) {
                // String - add $ suffix if needed
                conststring32 tempName = Melder_peek8to32(name.c_str());
                conststring32 varNameRaw;
                if (Melder_endsWith(tempName, U"$")) {
                    varNameRaw = tempName;
                } else {
                    varNameRaw = Melder_cat(tempName, U"$");
                }
                InterpreterVariable var = Interpreter_lookUpVariable(ptr.get(), varNameRaw);
                var->stringValue = Melder_dup_f(Melder_peek8to32(CHAR(STRING_ELT(value, 0))));
                
            } else if ((Rf_isReal(value) || Rf_isInteger(value)) && Rf_length(value) > 1) {
                // Vector - add # suffix if needed
                conststring32 tempName = Melder_peek8to32(name.c_str());
                conststring32 varNameRaw;
                if (Melder_endsWith(tempName, U"#") && !Melder_endsWith(tempName, U"##")) {
                    varNameRaw = tempName;
                } else {
                    varNameRaw = Melder_cat(tempName, U"#");
                }
                NumericVector vec(value);
                InterpreterVariable var = Interpreter_lookUpVariable(ptr.get(), varNameRaw);
                // Create temporary VEC and copy data
                autoVEC temp = raw_VEC(vec.length());
                for (int i = 0; i < vec.length(); i++) {
                    temp[i+1] = vec[i];  // 0-based -> 1-based
                }
                var->numericVectorValue = temp.move();
            } else {
                stop("Unsupported R type for Praat variable");
            }
        } catch (MelderError) {
            std::string error_msg = Melder_peek32to8(Melder_getError());
            Melder_clearError();
            stop(error_msg);
        }
    }

    // =========================================================================
    // XPtr Access (for compatibility with existing code)
    // =========================================================================

    SEXP get_xptr() {
        return ptr;
    }
};

// =============================================================================
// Module Registration
// =============================================================================

RCPP_MODULE(interpreter_module) {
    class_<RInterpreter>("RInterpreter")
        .constructor("Create a new Praat interpreter instance")
        
        // Validation
        .method("is_valid", &RInterpreter::is_valid, 
                "Check if the interpreter pointer is valid")
        
        // Script execution
        .method("run", &RInterpreter::run,
                "Execute a Praat script")
        
        // Expression evaluation
        .method("eval_numeric", &RInterpreter::eval_numeric,
                "Evaluate a numeric expression")
        .method("eval_string", &RInterpreter::eval_string,
                "Evaluate a string expression")
        .method("eval_vector", &RInterpreter::eval_vector,
                "Evaluate a numeric vector expression")
        .method("eval_matrix", &RInterpreter::eval_matrix,
                "Evaluate a numeric matrix expression")
        .method("eval_string_array", &RInterpreter::eval_string_array,
                "Evaluate a string array expression")
        
        // Variable management
        .method("get_variable", &RInterpreter::get_variable,
                "Get a variable value from the interpreter")
        .method("set_variable", &RInterpreter::set_variable,
                "Set a variable value in the interpreter")
        
        // XPtr access
        .method("get_xptr", &RInterpreter::get_xptr,
                "Get the underlying XPtr (for compatibility)")
    ;
}
