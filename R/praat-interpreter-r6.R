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
    #'   x# for vector, x## for matrix)
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
