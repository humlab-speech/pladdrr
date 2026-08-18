# Typed error reporting (design principle 6).
#
# C++ wrappers (see src/pladdrr_errors.h) tag errors with a structured prefix
#   "[pladdrr_<class>:<routine>:<param>] <message>"
# so that R-side callers can distinguish input errors, Praat-side failures, and
# data-loss warnings cleanly via tryCatch().
#
# Public entry point:
#   with_pladdrr_errors(expr)
#     — wraps a call so that tagged C++ errors/warnings become classed R
#       conditions:
#         pladdrr_input_error  — invalid argument or precondition failed
#         pladdrr_praat_error  — Praat-internal failure
#         pladdrr_data_loss    — output incomplete vs requested range; the
#                                return value carries attr(., "pladdrr_data_loss")
#
# Hierarchy: each class inherits from "pladdrr_error" -> "error" -> "condition"
# (warnings inherit from "pladdrr_warning" -> "warning" -> "condition").
#
# The tag is parsed once; if it doesn't match, the original condition is
# rethrown untouched so non-pladdrr errors stay unwrapped.

.pladdrr_tag_re <- "^\\[pladdrr_([a-z_]+):([^:]*):([^\\]]*)\\] (.*)$"

.parse_pladdrr_tag <- function(msg) {
  # perl=TRUE required: the pattern uses \] inside a bracket expression, which
  # only parses correctly under PCRE (TRE never matches, silently disabling the
  # whole typed-error contract).
  m <- regmatches(msg, regexec(.pladdrr_tag_re, msg, perl = TRUE))[[1]]
  if (length(m) != 5L) return(NULL)
  list(class = paste0("pladdrr_", m[2L]),
       routine = m[3L],
       param = m[4L],
       message = m[5L])
}

#' Build a classed pladdrr error condition
#' @return A condition object with class \code{c(klass, "pladdrr_error", "error", "condition")}
#'   and elements \code{message}, \code{call}, \code{routine}, \code{param}.
#' @examples
#' cond <- pladdrr:::pladdrr_error_cond(
#'   "pladdrr_input_error", "example_routine", "x", "bad value"
#' )
#' conditionMessage(cond)
#' @keywords internal
pladdrr_error_cond <- function(klass, routine, param, message, call = sys.call(-1L)) {
  structure(
    class = c(klass, "pladdrr_error", "error", "condition"),
    list(message = message, call = call, routine = routine, param = param)
  )
}

#' Build a classed pladdrr warning condition
#' @return A condition object with class \code{c(klass, "pladdrr_warning", "warning", "condition")}
#'   and elements \code{message}, \code{call}, \code{routine}, \code{param}.
#' @examples
#' cond <- pladdrr:::pladdrr_warning_cond(
#'   "pladdrr_data_loss", "example_routine", "x", "value out of range"
#' )
#' conditionMessage(cond)
#' @keywords internal
pladdrr_warning_cond <- function(klass, routine, param, message, call = sys.call(-1L)) {
  structure(
    class = c(klass, "pladdrr_warning", "warning", "condition"),
    list(message = message, call = call, routine = routine, param = param)
  )
}

#' Run an expression, reclassifying tagged pladdrr C++ errors/warnings.
#'
#' Any error or warning whose message matches the
#' \code{"[pladdrr_<class>:<routine>:<param>] <message>"} tag is rethrown as a
#' classed R condition. Untagged conditions pass through unchanged.
#'
#' Class hierarchy:
#' \itemize{
#'   \item \code{pladdrr_input_error} — invalid argument or precondition failed
#'   \item \code{pladdrr_praat_error} — Praat-internal failure
#'   \item \code{pladdrr_data_loss}   — output incomplete vs requested range
#' }
#' All inherit from \code{pladdrr_error} so a single
#' \code{tryCatch(pladdrr_error = ...)} catches them all.
#'
#' Data-loss warnings additionally attach
#' \code{attr(., "pladdrr_data_loss")} to the result, listing every routine
#' that reported missing values during the call.
#'
#' The reaction to data loss is controlled by
#' \code{options(pladdrr.data_loss = )}: \code{"warn"} (default) raises a
#' classed warning per incident, \code{"error"} stops at the first incident,
#' \code{"silent"} only records the attribute.
#'
#' @param expr expression to evaluate
#' @return value of \code{expr}, possibly with a \code{pladdrr_data_loss}
#'   attribute.
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
#' formant <- sound$to_formant_burg()
#' tryCatch(
#'   with_pladdrr_errors(
#'     pladdrr:::formant_get_multiple_formants_at_times(
#'       formant$.xptr, times = c(0.1, 0.2), formant_numbers = 0L
#'     )
#'   ),
#'   pladdrr_input_error = function(e) message("bad input: ", conditionMessage(e))
#' )
#' @export
with_pladdrr_errors <- function(expr) {
  loss_env <- new.env(parent = emptyenv())
  loss_env$items <- list()
  result <- withCallingHandlers(
    tryCatch(
      expr,
      error = function(e) {
        tag <- .parse_pladdrr_tag(conditionMessage(e))
        if (is.null(tag)) stop(e)
        cond <- pladdrr_error_cond(tag$class, tag$routine, tag$param, tag$message,
                                   call = conditionCall(e))
        stop(cond)
      }
    ),
    warning = function(w) {
      tag <- .parse_pladdrr_tag(conditionMessage(w))
      if (is.null(tag)) return(invisible())
      loss_env$items[[length(loss_env$items) + 1L]] <-
        list(routine = tag$routine, message = tag$message)
      mode <- getOption("pladdrr.data_loss", "warn")
      if (identical(mode, "error")) {
        stop(pladdrr_error_cond(tag$class, tag$routine, tag$param, tag$message,
                                call = conditionCall(w)))
      }
      if (!identical(mode, "silent")) {
        # Surface as a classed warning but keep going.
        warning(pladdrr_warning_cond(tag$class, tag$routine, tag$param, tag$message,
                                     call = conditionCall(w)))
      }
      invokeRestart("muffleWarning")
    }
  )
  if (length(loss_env$items) > 0L && !is.null(result)) {
    attr(result, "pladdrr_data_loss") <- loss_env$items
  }
  result
}
