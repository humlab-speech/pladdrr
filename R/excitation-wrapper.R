#' @title Praat Excitation Object
#' @description
#' Praat Excitation object with direct C++ module binding for auditory modeling.
#'
#' @details
#' An Excitation pattern represents the perceptual loudness distribution across
#' the auditory frequency range, measured in Bark scale.
#'
#' @return An \code{Excitation} object with methods for auditory excitation pattern analysis.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' spectrum <- sound$to_spectrum()
#' excitation <- spectrum$to_excitation()
#' excitation$get_loudness()
#'
#' @name Excitation
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.excitation_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query
.excitation_methods$get_loudness <- function(.self) .self$.cpp$get_loudness()
.excitation_methods$get_value_at_frequency <- function(.self, freq_bark) {
  .self$.cpp$get_value_at_frequency(as.numeric(freq_bark))
}
.excitation_methods$get_distance <- function(.self, other) {
  if (!inherits(other, "Excitation")) stop("other must be an Excitation object")
  .self$.cpp$get_distance(other$.xptr)
}

# Conversion
.excitation_methods$to_formant <- function(.self, max_formants = 20) {
  ptr <- .excitation_to_formant(.self$.xptr, as.integer(max_formants))
  Formant(.xptr = ptr)
}

# Export
.excitation_methods$as_vector <- function(.self) {
  v <- .self$.cpp$as_vector()
  names(v) <- paste0("bin_", seq_along(v))
  v
}
.excitation_methods$as_data_frame <- function(.self) {
  df <- .self$.cpp$as_data_frame()
  names(df) <- c("frequency_bark", "excitation")
  df
}

# Utility
.excitation_methods$get_xptr <- function(.self) .self$.xptr

# Print
.excitation_methods$print <- function(.self) {
  cat("<Praat Excitation>\n")
  cat(sprintf("  Frequency range: %.2f to %.2f Bark\n",
              .self$.cpp$get_fmin(), .self$.cpp$get_fmax()))
  cat(sprintf("  Number of bins: %d\n", .self$.cpp$get_number_of_bins()))
  cat(sprintf("  Loudness: %.2f sones\n", .self$.cpp$get_loudness()))
  invisible(.self)
}

.excitation_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.excitation_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Excitation
#' @export
`$.Excitation` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .excitation_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Excitation <- function(.xptr) {
  if (missing(.xptr) || is.null(.xptr)) {
    stop("Excitation objects should be created via Spectrum$to_excitation() or Cochleagram$to_excitation()")
  }
  
  exc_mod <- get_module("excitation_module")
  cpp_obj <- exc_mod$RExcitation$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Excitation", "PraatObject"))
}

#' @export
print.Excitation <- function(x, ...) x$print()

#' @export
as.data.frame.Excitation <- function(x, ...) x$as_data_frame()
