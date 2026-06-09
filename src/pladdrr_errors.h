// pladdrr_errors.h — typed error reporting helpers.
//
// Design principle 6: robust user-facing error reporting incl. data loss.
//
// Errors thrown from C++ wrappers are plain Rcpp::exception by default — R-side
// callers cannot distinguish "invalid input" from "internal Praat failure" from
// "data loss" without parsing free-form message strings.
//
// Pattern used here: every wrapper-side throw prepends a structured tag of the
// form `[pladdrr_<class>:<routine>:<param>] <message>`. The R-side helper
// `pladdrr_reclassify_error()` (R/error-classes.R) matches that tag and
// rethrows the condition with an R class hierarchy
//   c("pladdrr_input_error" | "pladdrr_data_loss" | "pladdrr_praat_error",
//     "pladdrr_error", "error", "condition")
// so callers can `tryCatch(pladdrr_input_error = ...)` cleanly.
//
// Data-loss warnings work the same way via Rcpp::warning(); R-side handler
// reclassifies them and attaches an attribute "pladdrr_data_loss" to the
// returned value when applicable.
//
// Usage:
//   if (sound->nx <= 0)
//       PLADDRR_STOP_INPUT("sound_get_duration", "nx", "zero-length signal");
//   if (clipped > 0)
//       PLADDRR_WARN_DATA_LOSS("sound_extract_part", "frames clipped to xmax");

#ifndef PLADDRR_ERRORS_H
#define PLADDRR_ERRORS_H

#include <Rcpp.h>
#include <string>
#include <sstream>

namespace pladdrr {

inline std::string tag_input_error(const char* routine, const char* param,
                                   const std::string& msg) {
    std::ostringstream s;
    s << "[pladdrr_input_error:" << routine << ":" << param << "] " << msg;
    return s.str();
}

inline std::string tag_praat_error(const char* routine, const std::string& msg) {
    std::ostringstream s;
    s << "[pladdrr_praat_error:" << routine << ":-] " << msg;
    return s.str();
}

inline std::string tag_data_loss(const char* routine, const std::string& msg) {
    std::ostringstream s;
    s << "[pladdrr_data_loss:" << routine << ":-] " << msg;
    return s.str();
}

}  // namespace pladdrr

#define PLADDRR_STOP_INPUT(routine, param, msg)                            \
    Rcpp::stop(pladdrr::tag_input_error((routine), (param),                \
                                        std::string(msg)))

#define PLADDRR_STOP_PRAAT(routine, msg)                                   \
    Rcpp::stop(pladdrr::tag_praat_error((routine), std::string(msg)))

#define PLADDRR_WARN_DATA_LOSS(routine, msg)                               \
    Rcpp::warning(pladdrr::tag_data_loss((routine), std::string(msg)))

// Common precondition: throw input error if XPtr is null.
#define PLADDRR_REQUIRE_PTR(routine, xptr, ptrname)                        \
    do {                                                                   \
        if (!(xptr) || (xptr).get() == nullptr) {                          \
            PLADDRR_STOP_INPUT((routine), (ptrname),                       \
                               "external pointer is null or invalid");    \
        }                                                                  \
    } while (0)

// Common precondition: throw if a numeric param is NA.
#define PLADDRR_REQUIRE_FINITE(routine, param, value)                      \
    do {                                                                   \
        double _v = (value);                                               \
        if (!R_finite(_v)) {                                               \
            PLADDRR_STOP_INPUT((routine), (param),                         \
                               "must be a finite number, got NA/NaN/Inf"); \
        }                                                                  \
    } while (0)

#endif  // PLADDRR_ERRORS_H
