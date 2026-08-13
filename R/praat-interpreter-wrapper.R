# praat-interpreter-r6.R
# R6 class for persistent Praat interpreter with state
#
# DESIGN NOTE: PraatInterpreter intentionally uses R6::R6Class instead of
# the module-based function factory pattern used by other Praat objects (30/31).
#
# REASON: The interpreter maintains persistent mutable state across method
# calls (variables, object list, script context). R6's reference semantics
# are the correct design pattern for this stateful behavior.
#
# PERFORMANCE: The interpreter is not called in tight loops like analysis
# objects, so the R6 overhead (~50ns per call) is negligible compared to
# script execution time (milliseconds to seconds).
#
# See docs/MODULE_VS_R6_DESIGN.md for detailed rationale.

# Helper: Wrap raw Praat pointer in appropriate R6 class
.wrap_praat_object <- function(xptr) {
  if (is.null(xptr)) return(NULL)

  class_name <- attr(xptr, "praat_class")
  if (is.null(class_name)) {
    warning("Object has no praat_class attribute, returning raw pointer")
    return(xptr)
  }

  # Map Praat class names to R6 constructors
  # Each R6 class should accept a .xptr parameter

  switch(class_name,
    "Sound" = Sound(.xptr = xptr),
    "Pitch" = Pitch(.xptr = xptr),
    "Formant" = Formant(.xptr = xptr),
    "Intensity" = Intensity(.xptr = xptr),
    "Spectrogram" = Spectrogram(.xptr = xptr),
    "Spectrum" = Spectrum(.xptr = xptr),
    "TextGrid" = TextGrid(.xptr = xptr),
    "PointProcess" = PointProcess(.xptr = xptr),
    "Harmonicity" = Harmonicity(.xptr = xptr),
    "LPC" = LPC(.xptr = xptr),
    "Ltas" = Ltas(.xptr = xptr),
    "Manipulation" = Manipulation(.xptr = xptr),
    "Matrix" = Matrix(.xptr = xptr),
    "Table" = Table(.xptr = xptr),
    "PitchTier" = PitchTier(.xptr = xptr),
    "FormantGrid" = FormantGrid(.xptr = xptr),
    "IntensityTier" = IntensityTier(.xptr = xptr),
    "DurationTier" = DurationTier(.xptr = xptr),
    "AmplitudeTier" = AmplitudeTier(.xptr = xptr),
    "Cochleagram" = Cochleagram(.xptr = xptr),
    "Excitation" = Excitation(.xptr = xptr),
    "PowerCepstrum" = PowerCepstrum(.xptr = xptr),
    "Cepstrum" = Cepstrum(.xptr = xptr),
    "VocalTract" = VocalTract(.xptr = xptr),
    "LongSound" = LongSound(.xptr = xptr),
    "FormantTier" = FormantTier(.xptr = xptr),
    {
      warning("Unknown Praat class: ", class_name, ", returning raw pointer")
      xptr
    }
  )
}

.praat_object_xptr <- function(object) {
  xptr <- .subset2(object, ".xptr")
  if (!is.null(xptr)) return(xptr)

  getter <- object$get_xptr
  if (is.function(getter)) return(getter())

  getter <- object$get_ptr
  if (is.function(getter)) return(getter())

  stop("Could not extract Praat external pointer from object")
}

#' Praat Script Interpreter
#'
#' R6 class for executing Praat scripts with persistent interpreter state.
#' Allows running multiple scripts while maintaining variables and state between runs.
#' Provides bidirectional object transfer between R and Praat's object list.
#'
#' @description
#' The PraatInterpreter provides a persistent Praat scripting environment within R.
#' Unlike one-shot script execution, the interpreter maintains state between calls,
#' enabling incremental script development and interactive exploration.
#'
#' @return An R6 object of class \code{PraatInterpreter}.
#'
#' @examples
#' # Create interpreter
#' interp <- PraatInterpreter$new()
#'
#' # Execute script
#' interp$run("
#'   Create Sound as pure tone: \"tone\", 1, 0, 1, 44100, 440, 0.2, 0.01, 0.01
#'   pitch = To Pitch: 0, 75, 600
#' ")
#'
#' # Get objects
#' interp$list_objects()
#' sound <- interp$get_object("tone")
#'
#' # Set and get variables
#' interp$set_variable("freq", 440)
#' interp$get_variable("freq")
#'
#' # Evaluate expressions
#' interp$eval("sqrt(2)")
#'
#' @seealso
#' \code{\link{Sound}}, \code{\link{Pitch}} for Praat object classes
#'
#' @export
PraatInterpreter <- R6::R6Class(
  "PraatInterpreter",

  public = list(
    #' @description
    #' Create a new interpreter instance with empty state.
    initialize = function() {
      # Load Rcpp Module
      interp_mod <- get_module("interpreter_module")
      private$cpp <- interp_mod$RInterpreter$new()
    },

    #' @description
    #' Execute Praat script code.
    #' @param script Character string with Praat script.
    #' @return Self (invisibly), for method chaining.
    run = function(script) {
      private$cpp$run(script)
      invisible(self)
    },

    #' @description
    #' Get a variable's value from the interpreter.
    #' @param name Variable name.
    #' @return Variable value.
    get_variable = function(name) {
      private$cpp$get_variable(name)
    },

    #' @description
    #' Set a variable's value in the interpreter.
    #' @param name Variable name.
    #' @param value Variable value.
    #' @return Self (invisibly).
    set_variable = function(name, value) {
      private$cpp$set_variable(name, value)
      invisible(self)
    },

    #' @description
    #' Evaluate a Praat expression and return the result.
    #' @param expression Praat expression.
    #' @return Result of the expression.
    eval = function(expression) {
      # Try to determine result type and evaluate using interpreter context
      # Try numeric first
      tryCatch({
        return(private$cpp$eval_numeric(expression))
      }, error = function(e) {
        # Try string
        tryCatch({
          return(private$cpp$eval_string(expression))
        }, error = function(e2) {
          # Try vector
          tryCatch({
            return(private$cpp$eval_vector(expression))
          }, error = function(e3) {
            # Try matrix
            tryCatch({
              return(private$cpp$eval_matrix(expression))
            }, error = function(e4) {
              # Try string array
              tryCatch({
                return(private$cpp$eval_string_array(expression))
              }, error = function(e5) {
                stop("Could not evaluate expression: ", expression,
                     "\nLast error: ", conditionMessage(e5))
              })
            })
          })
        })
      })
    },

    #' @description
    #' Get the count of objects in the Praat object list.
    #' @return Integer count.
    object_count = function() {
      .praat_interpreter_object_count()
    },

    #' @description
    #' List all objects in the Praat object list.
    #' @return A data.frame with id, name, class, and selected columns.
    list_objects = function() {
      .praat_interpreter_list_objects()
    },

    # ==========================================================================
    # Object Bridge: Transfer objects between R and Praat
    # ==========================================================================

    #' @description
    #' Get a Praat object from the interpreter's object list.
    #' @param name Object name.
    #' @param type Expected type (optional).
    #' @return An R6 object.
    get_object = function(name, type = NULL) {
      expected_type <- if (is.null(type)) "" else type
      xptr <- .praat_interpreter_get_object(name, expected_type)
      .wrap_praat_object(xptr)
    },

    #' @description
    #' Get a Praat object by ID.
    #' @param id Object ID.
    #' @return An R6 object.
    get_object_by_id = function(id) {
      xptr <- .praat_interpreter_get_object_by_id(as.integer(id))
      .wrap_praat_object(xptr)
    },

    #' @description
    #' Add an R object to Praat's object list.
    #' @param name Object name.
    #' @param object A PraatObject.
    #' @return Object ID (invisibly).
    set_object = function(name, object) {
      if (!inherits(object, "PraatObject")) {
        stop("object must be a PraatObject (Sound, Pitch, etc.)")
      }
      xptr <- .praat_object_xptr(object)
      class_name <- class(object)[1]
      id <- .praat_interpreter_set_object(xptr, name, class_name)
      invisible(id)
    },

    #' @description
    #' Remove an object from Praat's object list by name.
    #' @param name Object name.
    #' @return Self (invisibly).
    remove_object = function(name) {
      .praat_interpreter_remove_object(name)
      invisible(self)
    },

    #' @description
    #' Remove an object from Praat's object list by ID.
    #' @param id Object ID.
    #' @return Self (invisibly).
    remove_object_by_id = function(id) {
      .praat_interpreter_remove_object_by_id(as.integer(id))
      invisible(self)
    },

    #' @description
    #' Select an object in Praat's object list.
    #' @param name Object name.
    #' @param add If TRUE, add to the current selection.
    #' @return Self (invisibly).
    select_object = function(name, add = FALSE) {
      .praat_interpreter_select_object(name, add)
      invisible(self)
    },

    #' @description
    #' Clear all objects from Praat's object list.
    #' @return Self (invisibly).
    clear_objects = function() {
      .praat_interpreter_clear_objects()
      invisible(self)
    },

    #' @description
    #' Print a summary of the interpreter's current object list.
    #' @return Self (invisibly).
    print = function() {
      cat("<PraatInterpreter>\n")
      n_objects <- self$object_count()
      cat("  Objects:", n_objects, "\n")
      if (n_objects > 0 && n_objects <= 5) {
        objs <- self$list_objects()
        for (i in seq_len(nrow(objs))) {
          sel <- if (objs$selected[i]) "*" else " "
          cat(sprintf("    %s[%d] %s %s\n", sel, objs$id[i], objs$class[i], objs$name[i]))
        }
      } else if (n_objects > 5) {
        cat("    (use $list_objects() to see all)\n")
      }
      invisible(self)
    }
  ),

  private = list(
    cpp = NULL  # Rcpp module instance
  )
)
