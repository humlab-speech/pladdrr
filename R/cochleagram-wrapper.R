#' Cochleagram
#'
#' Praat Cochleagram object with direct C++ module binding for auditory modeling.
#'
#' A Cochleagram represents the output of a bank of auditory filters arranged
#' along the basilar membrane. Frequency is measured in Bark units (0-25.6 Bark).
#'
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Cochleagram object; set internally when a method returns a new
#'   Cochleagram.
#' @return A \code{Cochleagram} object with methods for auditory filter-bank analysis in Bark scale.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 44100)
#' cochleagram <- sound$to_cochleagram()
#' cochleagram$get_duration()
#' cochleagram$get_loudness_at_time(0.15)
#'
#' @name Cochleagram
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.cochleagram_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Time domain
.cochleagram_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.cochleagram_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.cochleagram_methods$get_duration <- function(.self) .self$.cpp$get_duration()
.cochleagram_methods$get_number_of_frames <- function(.self) .self$.cpp$get_number_of_frames()
.cochleagram_methods$get_time_step <- function(.self) .self$.cpp$get_time_step()
.cochleagram_methods$get_time_from_column <- function(.self, i_col) {
  .self$.cpp$get_time_from_column(as.integer(i_col))
}

# Query - Frequency domain
.cochleagram_methods$get_lowest_frequency <- function(.self) .self$.cpp$get_ymin()
.cochleagram_methods$get_highest_frequency <- function(.self) .self$.cpp$get_ymax()
.cochleagram_methods$get_number_of_frequency_bands <- function(.self) {
  .self$.cpp$get_number_of_frequency_bands()
}
.cochleagram_methods$get_frequency_step <- function(.self) .self$.cpp$get_frequency_step()
.cochleagram_methods$get_frequency_from_row <- function(.self, i_row) {
  .self$.cpp$get_frequency_from_row(as.integer(i_row))
}

# Query - Values
.cochleagram_methods$get_value_at_time_and_frequency <- function(.self, time, freq_bark) {
  .self$.cpp$get_value_at_time_and_frequency(as.numeric(time), as.numeric(freq_bark))
}
.cochleagram_methods$get_loudness_at_time <- function(.self, time) {
  .self$to_excitation(as.numeric(time))$get_loudness()
}

# Transformations
.cochleagram_methods$to_excitation <- function(.self, time) {
  xptr <- .cochleagram_to_excitation(.self$.xptr, as.numeric(time))
  Excitation(.xptr = xptr)
}

.cochleagram_methods$get_difference <- function(.self, other, tmin = 0, tmax = 0) {
  if (!inherits(other, "Cochleagram")) stop("other must be a Cochleagram object")
  .self$.cpp$get_difference(other$.xptr, as.numeric(tmin), as.numeric(tmax))
}

# Export
.cochleagram_methods$as_matrix <- function(.self) {
  .self$.cpp$as_matrix()
}

# Utility
.cochleagram_methods$get_xptr <- function(.self) .self$.xptr

# Print
.cochleagram_methods$print <- function(.self) {
  cat("<Praat Cochleagram>\n")
  cat(sprintf("  Time domain: %.3f to %.3f s\n", .self$.cpp$get_xmin(), .self$.cpp$get_xmax()))
  cat(sprintf("  Frequency range: %.2f to %.2f Bark\n", .self$.cpp$get_ymin(), .self$.cpp$get_ymax()))
  cat(sprintf("  %d frames x %d frequency bands\n",
              .self$.cpp$get_number_of_frames(), .self$.cpp$get_number_of_frequency_bands()))
  invisible(.self)
}

.cochleagram_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.cochleagram_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Cochleagram
#' @export
`$.Cochleagram` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .cochleagram_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Cochleagram <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Cochleagram objects should be created via Sound$to_cochleagram() or Sound$to_cochleagram_edb()")
  }
  
  coch_mod <- get_module("cochleagram_module")
  cpp_obj <- coch_mod$RCochleagram$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Cochleagram", "PraatObject"))
}

#' @export
print.Cochleagram <- function(x, ...) x$print()
