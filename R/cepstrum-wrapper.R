#' @title Praat Cepstrum Object
#' @description
#' Praat Cepstrum object with direct C++ module binding.
#'
#' @details
#' The cepstrum is the inverse Fourier transform of the logarithm of the spectrum.
#' Unlike PowerCepstrum, it preserves phase information.
#'
#' @return A \code{Cepstrum} object with methods for cepstral analysis and quefrency-domain processing.
#'
#' @examples
#' sound <- Sound$create_tone(frequency = 150, duration = 0.3)
#' cepstrum <- sound$to_cepstrum()
#' spectrum <- cepstrum$to_spectrum()
#'
#' @name Cepstrum
NULL

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.cepstrum_methods <- new.env(hash = TRUE, parent = emptyenv())

# Conversion
.cepstrum_methods$to_sound <- function(.self) {
  xptr <- .cepstrum_to_sound(.self$.xptr)
  Sound(.xptr = xptr)  # Bug fix: was Sound$new(xptr) in old code
}
.cepstrum_methods$to_spectrum <- function(.self) {
  xptr <- .cepstrum_to_spectrum(.self$.xptr)
  Spectrum(.xptr = xptr)
}
.cepstrum_methods$to_powercepstrum <- function(.self) {
  xptr <- .cepstrum_to_powercepstrum(.self$.xptr)
  PowerCepstrum(.xptr = xptr)
}
# Praat-compatible alias
.cepstrum_methods$to_power_cepstrum <- function(.self) {
  xptr <- .cepstrum_to_powercepstrum(.self$.xptr)
  PowerCepstrum(.xptr = xptr)
}

# Utility
.cepstrum_methods$get_xptr <- function(.self) .self$.xptr

# Print
.cepstrum_methods$print <- function(.self) {
  cat("<Praat Cepstrum>\n")
  cat(sprintf("  Quefrency range: %.4f to %.4f s\n",
              .self$.cpp$get_qmin(), .self$.cpp$get_qmax()))
  cat(sprintf("  Number of coefficients: %d\n", .self$.cpp$get_number_of_coefficients()))
  invisible(.self)
}

.cepstrum_methods$is_valid <- function(.self) .self$.cpp$is_valid()

# Export
.cepstrum_methods$as_data_frame <- function(.self) .self$.cpp$as_data_frame()
.cepstrum_methods$as_vector <- function(.self) .self$.cpp$as_vector()
lockEnvironment(.cepstrum_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Cepstrum
#' @export
`$.Cepstrum` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .cepstrum_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Cepstrum <- function(.xptr) {
  if (!inherits(.xptr, "externalptr")) {
    stop(".xptr must be an external pointer")
  }
  
  ceps_mod <- get_module("cepstrum_module")
  cpp_obj <- ceps_mod$RCepstrum$new(.xptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr
  ), class = c("Cepstrum", "PraatObject"))
}

