#' @title Base Class for Praat Objects
#' @description
#' Abstract base class for all Praat object wrappers. Manages external
#' pointers to C++ Praat objects with automatic memory cleanup.
#'
#' @details
#' This is an abstract R6 class that should not be instantiated directly.
#' It provides common functionality for all Praat object types:
#' - External pointer management
#' - Automatic cleanup via finalizers
#' - Pointer validation
#'
#' Derived classes (Sound, Pitch, Formant, etc.) inherit from this base class.
#'
#' @keywords internal
#' @export
PraatObject <- R6::R6Class(
  "PraatObject",
  
  public = list(
    #' @description
    #' Initialize a Praat object (abstract - should not be called directly)
    #' @param ptr External pointer to C++ Praat object
    initialize = function(ptr = NULL) {
      if (is.null(ptr)) {
        stop("PraatObject is abstract and cannot be instantiated directly")
      }
      private$validate_pointer(ptr)
      private$ptr <- ptr
    },
    
    #' @description
    #' Check if the object's pointer is valid
    #' @return logical TRUE if pointer is valid
    is_valid = function() {
      !is.null(private$ptr) && 
        inherits(private$ptr, "externalptr") &&
        !identical(private$ptr, new.env()) # Check if not null pointer
    },
    
    #' @description
    #' Get the class name of the Praat object
    #' @return character Class name
    get_class_name = function() {
      class(self)[1]
    },
    
    #' @description
    #' Print method for Praat objects
    print = function() {
      cat(sprintf("<%s>\n", self$get_class_name()))
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      }
      invisible(self)
    }
  ),
  
  private = list(
    # External pointer to C++ Praat object
    ptr = NULL,
    
    # Validate that pointer is an externalptr
    validate_pointer = function(ptr) {
      if (!inherits(ptr, "externalptr")) {
        stop("ptr must be an external pointer")
      }
    },
    
    # Finalizer called when R object is garbage collected
    finalize = function() {
      # XPtr finalizer in C++ will handle actual cleanup
      # Just set to NULL here
      private$ptr <- NULL
    }
  ),
  
  # Lock the class to prevent adding fields after creation
  lock_class = TRUE
)
