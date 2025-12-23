# praat-interpreter-r6.R
# R6 class for persistent Praat interpreter with state

#' Praat Script Interpreter
#'
#' R6 class for executing Praat scripts with persistent interpreter state.
#' Allows running multiple scripts while maintaining variables and state between runs.
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
    
    #' @description Print method
    print = function() {
      cat("<PraatInterpreter>\n")
      cat("  Status: active\n")
      invisible(self)
    }
  ),
  
  private = list(
    ptr = NULL
  )
)
