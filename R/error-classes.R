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
#         pladdrr_data_loss    — output incomplete vs requested range, or input
#           shorter than its own header (a WAV read shorter than its `data`
#           chunk claims); for these, attr(., "pladdrr_data_loss") on the value
#           returned by with_pladdrr_errors() lists the routines that reported it
#
# Classes raised at R level are already classed and pass through untouched (they
# carry $routine/$message on the condition, not an attribute on the value):
#         pladdrr_data_loss         — .warn_data_loss(), e.g. a truncated WAV in
#           .sound_ptr_from_path(); options(pladdrr.data_loss =) governs it
#         pladdrr_decoder_fallback  — the native reader refused the file and av
#           decoded it; deliberately NOT governed by that option
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
#' @return A condition object with class \code{c(klass, "pladdrr_error",
#'  "error", "condition")}
#'   and elements \code{message}, \code{call}, \code{routine}, \code{param}.
#' @examples
#' cond <- pladdrr:::pladdrr_error_cond(
#'   "pladdrr_input_error", "example_routine", "x", "bad value"
#' )
#' conditionMessage(cond)
#' @keywords internal
#' @noRd
pladdrr_error_cond <- function(klass, routine, param, message,
  call = sys.call(-1L)) {
  structure(
    class = c(klass, "pladdrr_error", "error", "condition"),
    list(message = message, call = call, routine = routine, param = param)
  )
}

# Turn a C++ exception that carries a pladdrr tag in its message into the
# classed condition; any other error is passed on unchanged.
.reraise_tagged <- function(e) {
  tag <- .parse_pladdrr_tag(conditionMessage(e))
  if (is.null(tag)) stop(e)
  stop(pladdrr_error_cond(tag$class, tag$routine, tag$param, tag$message,
                          call = conditionCall(e)))
}

# The direct getters are called in loops, so they get this tryCatch-only
# version of with_pladdrr_errors() (no data-loss warning bookkeeping).
.direct_door <- function(expr) tryCatch(expr, error = .reraise_tagged)

#' Build a classed pladdrr warning condition
#' @return A condition object with class \code{c(klass, "pladdrr_warning",
#'  "warning", "condition")}
#'   and elements \code{message}, \code{call}, \code{routine}, \code{param}.
#' @examples
#' cond <- pladdrr:::pladdrr_warning_cond(
#'   "pladdrr_data_loss", "example_routine", "x", "value out of range"
#' )
#' conditionMessage(cond)
#' @keywords internal
#' @noRd
pladdrr_warning_cond <- function(klass, routine, param, message,
  call = sys.call(-1L)) {
  structure(
    class = c(klass, "pladdrr_warning", "warning", "condition"),
    list(message = message, call = call, routine = routine, param = param)
  )
}

#' Run an expression, reclassifying tagged pladdrr C++ errors and warnings
#'
#' Any error or warning whose message matches the
#' \code{"[pladdrr_<class>:<routine>:<param>] <message>"} tag is rethrown as a
#' classed R condition. Untagged conditions pass through unchanged.
#'
#' Class hierarchy:
#' \itemize{
#'   \item \code{pladdrr_input_error} — invalid argument or precondition failed
#'   \item \code{pladdrr_praat_error} — Praat-internal failure
#'   \item \code{pladdrr_data_loss}   — output incomplete vs requested range, or
#'     input shorter than its own header (a WAV read shorter than the length its
#'     \code{data} chunk declares)
#'   \item \code{pladdrr_decoder_fallback} — the native reader refused the file
#'     and the \code{av} fallback decoded it instead
#' }
#' The error classes inherit from \code{pladdrr_error} and the warning classes
#' from \code{pladdrr_warning}, so \code{tryCatch(pladdrr_error = ...)} catches
#' the failures; \code{pladdrr_data_loss} as a warning and
#' \code{pladdrr_decoder_fallback} are caught as warnings.
#'
#' Only conditions carrying the C++ tag above are reclassified here. The ones
#' pladdrr raises at R level are already classed and pass through unchanged:
#' \code{pladdrr_data_loss} from \code{.warn_data_loss()} (out-of-range
#' extraction, and a file read shorter than its own header) and
#' \code{pladdrr_decoder_fallback} from the \code{av} fallback in
#' \code{Sound(path = )}. Those two need no \code{with_pladdrr_errors()}; they
#' carry \code{$routine} and \code{$message} on the condition, and no attribute
#' on the value they interrupted.
#'
#' Data loss reported by a tagged C++ routine additionally attaches
#' \code{attr(., "pladdrr_data_loss")} to the value
#' \code{with_pladdrr_errors()} returns, listing every routine that reported
#' missing values during the call. Values that take no attributes (an external
#' pointer, an R6 object) get none.
#'
#' The reaction to data loss is controlled by
#' \code{options(pladdrr.data_loss = )}: \code{"warn"} (default) raises a
#' classed warning per incident, \code{"error"} stops at the first incident,
#' \code{"silent"} only records the attribute. It does not govern
#' \code{pladdrr_decoder_fallback}: a decode that succeeded lost nothing.
#'
#' @param expr expression to evaluate
#' @return value of \code{expr}, possibly with a \code{pladdrr_data_loss}
#'   attribute.
#' @examples
#' sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate =
#'  16000)
#' formant <- sound$to_formant_burg()
#' tryCatch(
#'   with_pladdrr_errors(
#'     pladdrr:::formant_get_multiple_formants_at_times(
#'       formant$.xptr, times = c(0.1, 0.2), formant_numbers = 0L
#'     )
#'   ),
#' pladdrr_input_error = function(e) message("bad input: ", conditionMessage(e))
#' )
#' @export
with_pladdrr_errors <- function(expr) {
  loss_env <- new.env(parent = emptyenv())
  loss_env$items <- list()
  result <- withCallingHandlers(
    tryCatch(
      expr,
      error = .reraise_tagged
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
        warning(
          pladdrr_warning_cond(tag$class, tag$routine, tag$param, tag$message,
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
