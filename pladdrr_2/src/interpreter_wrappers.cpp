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
#include "praat.github.io/melder/melder_info.h"
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

// [[Rcpp::export(.praat_evaluate_matrix)]]
NumericMatrix praat_evaluate_matrix(std::string expression) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        MAT mat;
        bool owned;
        Interpreter_numericMatrixExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &mat, &owned);
        
        // Copy to R matrix (1-based -> 0-based indexing)
        NumericMatrix result(mat.nrow, mat.ncol);
        for (integer i = 1; i <= mat.nrow; i++) {
            for (integer j = 1; j <= mat.ncol; j++) {
                result(i-1, j-1) = mat[i][j];
            }
        }
        
        // Note: mat is automatically freed by autoInterpreter destructor
        
        return result;
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_evaluate_string_array)]]
CharacterVector praat_evaluate_string_array(std::string expression) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    try {
        autoInterpreter interpreter = Interpreter_create();
        STRVEC strvec;
        bool owned;
        Interpreter_stringArrayExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &strvec, &owned);
        
        // Copy to R character vector
        CharacterVector result(strvec.size);
        for (integer i = 1; i <= strvec.size; i++) {
            result[i-1] = Melder_peek32to8(strvec[i]);
        }
        
        // Note: strvec is automatically freed by autoInterpreter destructor
        
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

// [[Rcpp::export(.praat_interpreter_create)]]
SEXP praat_interpreter_create() {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    try {
        autoInterpreter interpreter = Interpreter_create();
        addPredefinedVariables(interpreter.get());
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

// [[Rcpp::export(.praat_interpreter_set_variable)]]
void praat_interpreter_set_variable(SEXP xptr, std::string name, SEXP value) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
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
            InterpreterVariable var = Interpreter_lookUpVariable(interpreter.get(), varNameRaw);
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
            InterpreterVariable var = Interpreter_lookUpVariable(interpreter.get(), varName.get());
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
            InterpreterVariable var = Interpreter_lookUpVariable(interpreter.get(), varNameRaw);
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
            InterpreterVariable var = Interpreter_lookUpVariable(interpreter.get(), varNameRaw);
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
            InterpreterVariable var = Interpreter_lookUpVariable(interpreter.get(), varNameRaw);
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

// ==============================================================================
// Context-Aware Expression Evaluation (uses interpreter state)
// ==============================================================================

// [[Rcpp::export(.praat_interpreter_eval_numeric)]]
double praat_interpreter_eval_numeric(SEXP xptr, std::string expression) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        double result;
        Interpreter_numericExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()), &result);
        return result;
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_interpreter_eval_string)]]
std::string praat_interpreter_eval_string(SEXP xptr, std::string expression) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        autostring32 result = Interpreter_stringExpression(interpreter.get(),
            Melder_peek8to32(expression.c_str()));
        return Melder_peek32to8(result.get());
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop(error_msg);
    }
}

// [[Rcpp::export(.praat_interpreter_eval_vector)]]
NumericVector praat_interpreter_eval_vector(SEXP xptr, std::string expression) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        VEC vec;
        bool owned;
        Interpreter_numericVectorExpression(interpreter.get(),
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

// [[Rcpp::export(.praat_interpreter_eval_matrix)]]
NumericMatrix praat_interpreter_eval_matrix(SEXP xptr, std::string expression) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        MAT mat;
        bool owned;
        Interpreter_numericMatrixExpression(interpreter.get(),
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

// [[Rcpp::export(.praat_interpreter_eval_string_array)]]
CharacterVector praat_interpreter_eval_string_array(SEXP xptr, std::string expression) {
    XPtr<structInterpreter> interpreter(xptr);
    if (!interpreter) stop("Invalid Interpreter pointer");
    
    try {
        STRVEC strvec;
        bool owned;
        Interpreter_stringArrayExpression(interpreter.get(),
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

// ==============================================================================
// Object Management (query global Praat object list)
// ==============================================================================

// [[Rcpp::export(.praat_interpreter_object_count)]]
int praat_interpreter_object_count() {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    // theCurrentPraatObjects is the global object list
    return theCurrentPraatObjects->n;
}

// [[Rcpp::export(.praat_interpreter_list_objects)]]
DataFrame praat_interpreter_list_objects() {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }
    
    int n = theCurrentPraatObjects->n;
    
    if (n == 0) {
        // Return empty data frame with correct columns
        return DataFrame::create(
            Named("id") = IntegerVector(),
            Named("name") = CharacterVector(),
            Named("class") = CharacterVector(),
            Named("selected") = LogicalVector()
        );
    }
    
    IntegerVector ids(n);
    CharacterVector names(n);
    CharacterVector classes(n);
    LogicalVector selected(n);
    
    for (int i = 0; i < n; i++) {
        int iobject = i + 1;  // Praat uses 1-based indexing
        ids[i] = theCurrentPraatObjects->list[iobject].id;
        names[i] = Melder_peek32to8(theCurrentPraatObjects->list[iobject].name.get());
        classes[i] = Melder_peek32to8(theCurrentPraatObjects->list[iobject].klas->className);
        selected[i] = theCurrentPraatObjects->list[iobject].isSelected;
    }
    
    return DataFrame::create(
        Named("id") = ids,
        Named("name") = names,
        Named("class") = classes,
        Named("selected") = selected
    );
}

// ==============================================================================
// Object Bridge: Transfer objects between interpreter and R
// ==============================================================================

// Helper: Find object index by name (returns -1 if not found)
static int find_object_by_name(const std::string& name) {
    autostring32 searchName = Melder_8to32(name.c_str());

    for (int iobject = 1; iobject <= theCurrentPraatObjects->n; iobject++) {
        // Check if name matches (Praat stores "Type name", we accept either)
        conststring32 fullName = theCurrentPraatObjects->list[iobject].name.get();
        conststring32 className = theCurrentPraatObjects->list[iobject].klas->className;

        // Match against full name "Type name" or just "name"
        if (Melder_equ(fullName, searchName.get())) {
            return iobject;
        }

        // Also try matching just the name part (after class name + space)
        // Build the prefixed name using MelderString
        static MelderString buffer;
        MelderString_empty(&buffer);
        MelderString_append(&buffer, className, U" ", searchName.get());
        if (Melder_equ(fullName, buffer.string)) {
            return iobject;
        }
    }
    return -1;
}

// Helper: Find object index by ID
static int find_object_by_id(integer id) {
    for (int iobject = 1; iobject <= theCurrentPraatObjects->n; iobject++) {
        if (theCurrentPraatObjects->list[iobject].id == id) {
            return iobject;
        }
    }
    return -1;
}

//' Get object from Praat object list by name
//' @param name Object name (e.g., "Sound mySound" or just "mySound")
//' @param expected_type Expected class name (e.g., "Sound"), or empty for any
//' @return External pointer to the Praat object (copy)
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_get_object)]]
SEXP praat_interpreter_get_object(std::string name, std::string expected_type) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    int iobject = find_object_by_name(name);
    if (iobject < 0) {
        stop("Object not found: " + name);
    }

    Daata original = theCurrentPraatObjects->list[iobject].object;
    conststring32 actualClass = theCurrentPraatObjects->list[iobject].klas->className;

    // Check type if specified
    if (!expected_type.empty()) {
        autostring32 expectedType32 = Melder_8to32(expected_type.c_str());
        if (!Melder_equ(actualClass, expectedType32.get())) {
            stop("Type mismatch: expected " + expected_type +
                 " but found " + Melder_peek32to8(actualClass));
        }
    }

    try {
        // Make a copy of the object (so R owns its own copy)
        autoDaata copy = _Data_copy(original);

        // Release ownership to get raw pointer
        // Note: Daata is already a pointer type (structDaata*)
        structDaata* rawPtr = copy.releaseToAmbiguousOwner();

        auto deleter = [](structDaata* thing) {
            if (thing != nullptr) {
                forget(thing);
            }
        };

        // Add class name as attribute for R to dispatch correctly
        Rcpp::XPtr<structDaata> xptr(rawPtr, deleter);
        xptr.attr("praat_class") = Melder_peek32to8(actualClass);

        return xptr;

    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to copy object: " + error_msg);
    }

    return R_NilValue;  // unreachable
}

//' Get object by ID from Praat object list
//' @param id Object ID number
//' @return External pointer to the Praat object (copy)
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_get_object_by_id)]]
SEXP praat_interpreter_get_object_by_id(int id) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    int iobject = find_object_by_id(id);
    if (iobject < 0) {
        stop("Object with ID " + std::to_string(id) + " not found");
    }

    Daata original = theCurrentPraatObjects->list[iobject].object;
    conststring32 actualClass = theCurrentPraatObjects->list[iobject].klas->className;

    try {
        autoDaata copy = _Data_copy(original);
        structDaata* rawPtr = copy.releaseToAmbiguousOwner();

        auto deleter = [](structDaata* thing) {
            if (thing != nullptr) {
                forget(thing);
            }
        };

        Rcpp::XPtr<structDaata> xptr(rawPtr, deleter);
        xptr.attr("praat_class") = Melder_peek32to8(actualClass);

        return xptr;

    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to copy object: " + error_msg);
    }

    return R_NilValue;
}

//' Add R object to Praat object list
//' @param xptr External pointer to Praat object (will be copied)
//' @param name Name for the object in Praat's list
//' @param class_name Class name (e.g., "Sound", "Pitch")
//' @return ID of the newly added object
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_set_object)]]
int praat_interpreter_set_object(SEXP xptr, std::string name, std::string class_name) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    // The XPtr wraps a structDaata* (which is what Daata is an alias for)
    // But R6 classes use XPtr<structSound>, XPtr<structPitch>, etc.
    // All of these inherit from structDaata, so we can cast
    Rcpp::XPtr<structDaata> ptr(xptr);
    if (!ptr) {
        stop("Invalid object pointer");
    }

    try {
        // Make a copy for Praat to own
        // ptr.get() returns structDaata* which is the same as Daata
        autoDaata copy = _Data_copy(ptr.get());

        // Add to Praat's object list with the given name
        autostring32 name32 = Melder_8to32(name.c_str());
        praat_new(std::move(copy), name32.get());

        // Return the ID of the newly added object
        return theCurrentPraatObjects->list[theCurrentPraatObjects->n].id;

    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to add object: " + error_msg);
    }

    return -1;
}

//' Remove object from Praat object list by name
//' @param name Object name
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_remove_object)]]
void praat_interpreter_remove_object(std::string name) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    int iobject = find_object_by_name(name);
    if (iobject < 0) {
        stop("Object not found: " + name);
    }

    try {
        praat_removeObject(iobject);
        praat_show();  // Update the object list display
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to remove object: " + error_msg);
    }
}

//' Remove object from Praat object list by ID
//' @param id Object ID
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_remove_object_by_id)]]
void praat_interpreter_remove_object_by_id(int id) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    int iobject = find_object_by_id(id);
    if (iobject < 0) {
        stop("Object with ID " + std::to_string(id) + " not found");
    }

    try {
        praat_removeObject(iobject);
        praat_show();
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to remove object: " + error_msg);
    }
}

//' Select object in Praat object list by name
//' @param name Object name
//' @param add If TRUE, add to selection; if FALSE, replace selection
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_select_object)]]
void praat_interpreter_select_object(std::string name, bool add = false) {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    int iobject = find_object_by_name(name);
    if (iobject < 0) {
        stop("Object not found: " + name);
    }

    try {
        if (!add) {
            // Deselect all first
            for (int i = 1; i <= theCurrentPraatObjects->n; i++) {
                if (theCurrentPraatObjects->list[i].isSelected) {
                    theCurrentPraatObjects->list[i].isSelected = false;
                    theCurrentPraatObjects->totalSelection--;
                }
            }
        }

        // Select the target object
        if (!theCurrentPraatObjects->list[iobject].isSelected) {
            theCurrentPraatObjects->list[iobject].isSelected = true;
            theCurrentPraatObjects->totalSelection++;
        }

        praat_show();
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to select object: " + error_msg);
    }
}

//' Clear all objects from Praat object list
//' @keywords internal
// [[Rcpp::export(.praat_interpreter_clear_objects)]]
void praat_interpreter_clear_objects() {
    if (!praat_interpreter_initialized) {
        praat_interpreter_init();
    }

    try {
        // Remove objects from end to beginning
        while (theCurrentPraatObjects->n > 0) {
            praat_removeObject(theCurrentPraatObjects->n);
        }
        praat_show();
    } catch (MelderError) {
        std::string error_msg = Melder_peek32to8(Melder_getError());
        Melder_clearError();
        stop("Failed to clear objects: " + error_msg);
    }
}
