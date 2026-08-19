# praat-interpreter.R
# R interface for Praat interpreter functionality

# Validate a single non-empty character string argument.
.check_character1 <- function(x, arg = "expression") {
  if (!is.character(x) || length(x) != 1L || !nzchar(x)) {
    stop(sprintf("'%s' must be a single non-empty character string", arg), call. = FALSE)
  }
  invisible(x)
}

#' Execute a Praat script
#'
#' Executes a Praat script with automatic interpreter initialization.
#' Objects created during script execution remain in Praat's internal object list.
#'
#' @param script Character string containing Praat script code
#' @return Invisibly returns NULL
#' @export
#' @examples
#' # Create a sound and extract pitch
#' praat_run_script('
#'   Create Sound from formula: "test", 1, 0, 1, 44100, "0.5 * sin(2*pi*440*x)"
#'   pitch = To Pitch: 0.0, 75, 600
#' ')
praat_run_script <- function(script) {
  .check_character1(script, "script")
  .praat_run_script(script)
  invisible(NULL)
}

#' Evaluate a numeric Praat expression
#'
#' @param expression Character string containing a Praat formula expression
#' @return Numeric value
#' @export
#' @examples
#' # Calculate value
#' result <- praat_eval_numeric("sqrt(16) + 2^3")
praat_eval_numeric <- function(expression) {
  .check_character1(expression, "expression")
  .praat_evaluate_numeric(expression)
}

#' Evaluate a string Praat expression
#'
#' @param expression Character string containing a Praat string formula
#' @return Character string
#' @export
#' @examples
#' # String operations
#' result <- praat_eval_string('"Hello" + " " + "World"')
praat_eval_string <- function(expression) {
  .check_character1(expression, "expression")
  .praat_evaluate_string(expression)
}

#' Evaluate a vector Praat expression
#'
#' @param expression Character string containing a Praat vector formula
#' @return Numeric vector
#' @export
#' @examples
#' # Create vector
#' vec <- praat_eval_vector("{ 1, 2, 3, 4, 5 }")
praat_eval_vector <- function(expression) {
  .check_character1(expression, "expression")
  .praat_evaluate_vector(expression)
}

#' Evaluate a matrix Praat expression
#'
#' @param expression Character string containing a Praat matrix formula
#' @return Numeric matrix
#' @export
#' @examples
#' # Create matrix
#' mat <- praat_eval_matrix("{{ 1, 2 }, { 3, 4 }}")
praat_eval_matrix <- function(expression) {
  .check_character1(expression, "expression")
  .praat_evaluate_matrix(expression)
}

#' Evaluate a string array Praat expression
#'
#' @param expression Character string containing a Praat string array formula
#' @return Character vector
#' @export
#' @examples
#' # Create string array
#' arr <- praat_eval_string_array('{ "hello", "world" }')
praat_eval_string_array <- function(expression) {
  .check_character1(expression, "expression")
  .praat_evaluate_string_array(expression)
}

#' Initialize Praat interpreter
#'
#' Manually initialize the Praat interpreter. Normally called automatically
#' when needed, but can be called explicitly to control timing.
#'
#' @return Invisibly returns NULL
#' @export
#' @examples
#' praat_init()
praat_init <- function() {
  .praat_interpreter_init()
  invisible(NULL)
}

#' Check if Praat interpreter is initialized
#'
#' @return Logical; TRUE if initialized, FALSE otherwise
#' @export
#' @examples
#' praat_init()
#' praat_initialized()
praat_initialized <- function() {
  .praat_is_initialized()
}

#' Get count of objects in Praat object list
#'
#' @return Integer count of objects
#' @export
#' @examples
#' count <- praat_object_count()
praat_object_count <- function() {
  .praat_interpreter_object_count()
}

#' List all objects in Praat object list
#'
#' @return Data frame with columns: id, name, class, selected
#' @export
#' @examples
#' objects <- praat_list_objects()
#' print(objects)
praat_list_objects <- function() {
  .praat_interpreter_list_objects()
}
