// praat_error_handling.h - Bridge between Praat MelderError and R exceptions
//
// Provides utilities to convert Praat's error handling to R exceptions

#ifndef PRAAT_ERROR_HANDLING_H
#define PRAAT_ERROR_HANDLING_H

#include <Rcpp.h>
#include "melder/melder.h"
#include "melder/melder_textencoding.h"
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
    conststring32 msg = Melder_getError();
    if (msg && msg[0] != U'\0') {
        conststring8 msg8 = Melder_peek32to8(msg);
        if (msg8) {
            return std::string(msg8);
        }
    }
    return "Unknown Praat error";
}

// Wrapper for Praat functions that might throw
template<typename Func>
void praat_try(Func&& func, const std::string& error_message) {
    try {
        func();
    } catch (MelderError) {
        std::string praat_error = get_melder_error();
        Melder_clearError();
        Rcpp::stop(error_message + ": " + praat_error);
    }
}

// Wrapper that returns a value
template<typename Func>
auto praat_try_return(Func&& func, const std::string& error_message) -> decltype(func()) {
    try {
        return func();
    } catch (MelderError) {
        std::string praat_error = get_melder_error();
        Melder_clearError();
        Rcpp::stop(error_message + ": " + praat_error);
    }
}

#endif // PRAAT_ERROR_HANDLING_H
