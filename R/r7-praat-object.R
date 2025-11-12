#' @title Base Class for Praat Objects (R7/S7)
#' @description
#' Abstract base class for all Praat object wrappers using S7/R7 object system.
#' Manages external pointers to C++ Praat objects with automatic memory cleanup.
#'
#' @details
#' This is an abstract S7 class that should not be instantiated directly.
#' It provides common functionality for all Praat object types:
#' - External pointer management
#' - Automatic cleanup via finalizers
#' - Pointer validation
#'
#' Derived classes (Sound, Pitch, Formant, etc.) inherit from this base class.
#'
#' @keywords internal
#' @import S7
NULL

# Validator for external pointers
is_valid_praat_pointer <- function(ptr) {
  if (is.null(ptr)) return(FALSE)
  if (!inherits(ptr, "externalptr")) return(FALSE)
  # Check if pointer is not null
  !identical(ptr, new("externalptr"))
}

#' @export
PraatObject_S7 <- S7::new_class(
  name = "PraatObject",
  package = "speaker",
  properties = list(
    ptr = S7::new_property(
      class = class_external_pointer,
      validator = function(value) {
        if (!is_valid_praat_pointer(value)) {
          "Invalid Praat object pointer (NULL or not an external pointer)"
        }
      }
    )
  ),
  validator = function(self) {
    if (is.null(self@ptr)) {
      "Praat object pointer cannot be NULL"
    }
  },
  constructor = function(ptr) {
    if (is.null(ptr)) {
      stop("PraatObject is abstract and cannot be instantiated with NULL pointer")
    }
    S7::new_object(
      S7::S7_class(),
      ptr = ptr
    )
  }
)

# Print method for base PraatObject
S7::method(print, PraatObject_S7) <- function(x, ...) {
  cat("<Praat Object>\n")
  cat("Class:", class(x)[1], "\n")
  cat("Pointer:", if (is_valid_praat_pointer(x@ptr)) "valid" else "invalid", "\n")
  invisible(x)
}

# Validity check method
#' @export
S7::method(is_valid, PraatObject_S7) <- function(object) {
  is_valid_praat_pointer(object@ptr)
}
