# praat-interpreter-r6.R
# R6 class for persistent Praat interpreter with state

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
    "Sound" = Sound$new(.xptr = xptr),
    "Pitch" = Pitch$new(.xptr = xptr),
    "Formant" = Formant$new(.xptr = xptr),
    "Intensity" = Intensity$new(.xptr = xptr),
    "Spectrogram" = Spectrogram$new(.xptr = xptr),
    "Spectrum" = Spectrum$new(.xptr = xptr),
    "TextGrid" = TextGrid$new(.xptr = xptr),
    "PointProcess" = PointProcess$new(.xptr = xptr),
    "Harmonicity" = Harmonicity$new(.xptr = xptr),
    "LPC" = LPC$new(.xptr = xptr),
    "Ltas" = Ltas$new(.xptr = xptr),
    "Manipulation" = Manipulation$new(.xptr = xptr),
    "Matrix" = Matrix$new(.xptr = xptr),
    "Table" = Table$new(.xptr = xptr),
    "PitchTier" = PitchTier$new(.xptr = xptr),
    "FormantGrid" = FormantGrid$new(.xptr = xptr),
    "IntensityTier" = IntensityTier$new(.xptr = xptr),
    "DurationTier" = DurationTier$new(.xptr = xptr),
    "AmplitudeTier" = AmplitudeTier$new(.xptr = xptr),
    "Cochleagram" = Cochleagram$new(.xptr = xptr),
    "Excitation" = Excitation$new(.xptr = xptr),
    "PowerCepstrum" = PowerCepstrum$new(.xptr = xptr),
    "Cepstrum" = Cepstrum$new(.xptr = xptr),
    "VocalTract" = VocalTract$new(.xptr = xptr),
    "LongSound" = LongSound$new(.xptr = xptr),
    "FormantTier" = FormantTier$new(.xptr = xptr),
    {
      warning("Unknown Praat class: ", class_name, ", returning raw pointer")
      xptr
    }
  )
}

#' Praat Script Interpreter
#'
#' R6 class for executing Praat scripts with persistent interpreter state.
#' Allows running multiple scripts while maintaining variables and state between runs.
#' Provides bidirectional object transfer between R and Praat's object list.
#'
#' @export
PraatInterpreter <- R6::R6Class(
  "PraatInterpreter",

  public = list(
    #' @description Create new interpreter instance
    #' @return A new PraatInterpreter object
    initialize = function() {
      private$ptr <- .praat_interpreter_create()
    },
    
    #' @description Execute Praat script code
    #' @param script Character string with Praat script
    #' @return Self (invisibly), for method chaining
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' interp$run('
    #'   Create Sound from formula: "test", 1, 0, 1, 44100, "sin(2*pi*440*x)"
    #'   duration = Get duration
    #' ')
    #' }
    run = function(script) {
      .praat_interpreter_run(private$ptr, script)
      invisible(self)
    },
    
    #' @description Get variable value from interpreter
    #' @param name Variable name (with suffix: x for numeric, x$ for string, 
    #'   x# for vector, x## for matrix, x$# for string array)
    #' @return Variable value (type depends on variable)
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' interp$run('x = 42')
    #' value <- interp$get_variable("x")
    #' }
    get_variable = function(name) {
      .praat_interpreter_get_variable(private$ptr, name)
    },
    
    #' @description Set variable value in interpreter
    #' @param name Variable name (suffix auto-detected from R type)
    #' @param value Variable value (numeric, string, vector, matrix, or character vector)
    #' @return Self (invisibly), for method chaining
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' interp$set_variable("x", 42)
    #' interp$set_variable("name", "test")
    #' interp$set_variable("data", c(1, 2, 3))
    #' }
    set_variable = function(name, value) {
      .praat_interpreter_set_variable(private$ptr, name, value)
      invisible(self)
    },
    
    #' @description Evaluate expression and return result
    #' @param expression Praat expression to evaluate
    #' @return Result of expression (type depends on expression)
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' result <- interp$eval("2 + 2")  # Returns 4
    #' result <- interp$eval("\"hello\"")  # Returns "hello"
    #' }
    eval = function(expression) {
      # Try to determine result type and evaluate using interpreter context
      # Try numeric first
      tryCatch({
        return(.praat_interpreter_eval_numeric(private$ptr, expression))
      }, error = function(e) {
        # Try string
        tryCatch({
          return(.praat_interpreter_eval_string(private$ptr, expression))
        }, error = function(e2) {
          # Try vector
          tryCatch({
            return(.praat_interpreter_eval_vector(private$ptr, expression))
          }, error = function(e3) {
            # Try matrix
            tryCatch({
              return(.praat_interpreter_eval_matrix(private$ptr, expression))
            }, error = function(e4) {
              # Try string array
              tryCatch({
                return(.praat_interpreter_eval_string_array(private$ptr, expression))
              }, error = function(e5) {
                stop("Could not evaluate expression: ", expression, 
                     "\nLast error: ", conditionMessage(e5))
              })
            })
          })
        })
      })
    },
    
    #' @description Get count of objects in Praat object list
    #' @return Integer count of objects
    object_count = function() {
      .praat_interpreter_object_count()
    },
    
    #' @description List all objects in Praat object list
    #' @return Data frame with columns: id, name, class, selected
    list_objects = function() {
      .praat_interpreter_list_objects()
    },

    # ==========================================================================
    # Object Bridge: Transfer objects between R and Praat
    # ==========================================================================

    #' @description Get Praat object from interpreter's object list
    #' @param name Object name (e.g., "Sound mySound" or just "mySound")
    #' @param type Expected type (e.g., "Sound"). If NULL, accepts any type.
    #' @return R6 object of the appropriate type
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' interp$run('Create Sound from formula: "test", 1, 0, 1, 44100, "sin(2*pi*440*x)"')
    #' sound <- interp$get_object("test", "Sound")
    #' sound$get_total_duration()  # Use as normal R6 object
    #' }
    get_object = function(name, type = NULL) {
      expected_type <- if (is.null(type)) "" else type
      xptr <- .praat_interpreter_get_object(name, expected_type)
      .wrap_praat_object(xptr)
    },

    #' @description Get Praat object by ID from interpreter's object list
    #' @param id Object ID number
    #' @return R6 object of the appropriate type
    get_object_by_id = function(id) {
      xptr <- .praat_interpreter_get_object_by_id(as.integer(id))
      .wrap_praat_object(xptr)
    },

    #' @description Add R object to Praat's object list
    #' @param name Name for the object in Praat's list (without type prefix)
    #' @param object R6 Praat object (Sound, Pitch, etc.)
    #' @return ID of the newly added object (invisibly)
    #' @examples
    #' \dontrun{
    #' interp <- PraatInterpreter$new()
    #' sound <- Sound$create_tone(440, duration = 1.0)
    #' interp$set_object("myTone", sound)
    #' # Now you can use it in Praat scripts:
    #' interp$run('selectObject: "Sound myTone"
    #'             Filter (one formant): 1000, 100')
    #' }
    set_object = function(name, object) {
      if (!inherits(object, "PraatObject")) {
        stop("object must be a PraatObject (Sound, Pitch, etc.)")
      }
      # Get the raw pointer from the R6 object
      xptr <- object$get_ptr()
      class_name <- class(object)[1]
      id <- .praat_interpreter_set_object(xptr, name, class_name)
      invisible(id)
    },

    #' @description Remove object from Praat's object list by name
    #' @param name Object name
    #' @return Self (invisibly), for method chaining
    remove_object = function(name) {
      .praat_interpreter_remove_object(name)
      invisible(self)
    },

    #' @description Remove object from Praat's object list by ID
    #' @param id Object ID
    #' @return Self (invisibly), for method chaining
    remove_object_by_id = function(id) {
      .praat_interpreter_remove_object_by_id(as.integer(id))
      invisible(self)
    },

    #' @description Select object in Praat's object list
    #' @param name Object name
    #' @param add If TRUE, add to selection; if FALSE, replace selection
    #' @return Self (invisibly), for method chaining
    select_object = function(name, add = FALSE) {
      .praat_interpreter_select_object(name, add)
      invisible(self)
    },

    #' @description Clear all objects from Praat's object list
    #' @return Self (invisibly), for method chaining
    clear_objects = function() {
      .praat_interpreter_clear_objects()
      invisible(self)
    },

    #' @description Print method
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
    ptr = NULL
  )
)
