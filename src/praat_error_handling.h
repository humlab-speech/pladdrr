// praat_error_handling.h - Bridge between Praat MelderError and R exceptions
//
// Provides utilities to convert Praat's error handling to R exceptions

#ifndef PRAAT_ERROR_HANDLING_H
#define PRAAT_ERROR_HANDLING_H

#include <Rcpp.h>
#include "praat/sys/melder.h"
#include <string>

// Execute a Praat function and convert MelderError to R exception
// Usage: PRAAT_CATCH(your_praat_function(), "Failed to do something");
#define PRAAT_CATCH(expr, msg) \
    try { \
        expr; \
    } catch (MelderError) { \
        std::string error_msg = get_melder_error(); \
        Melder_clearError(); \
        Rcpp::stop(std::string(msg) + ": " + error_msg); \
    }

// Get current Melder error as string
inline std::string get_melder_error() {
    // MelderError captures the error message
    // We need to get it before clearing
    // For now, return generic message - can be enhanced later
    return "Praat error occurred";
}

// Wrapper for Praat functions that might throw
template<typename Func>
void praat_try(Func&& func, const std::string& error_message) {
    try {
        func();
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop(error_message);
    }
}

// Wrapper that returns a value
template<typename Func>
auto praat_try_return(Func&& func, const std::string& error_message) -> decltype(func()) {
    try {
        return func();
    } catch (MelderError) {
        Melder_clearError();
        Rcpp::stop(error_message);
    }
}

#endif // PRAAT_ERROR_HANDLING_H
