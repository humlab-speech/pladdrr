#' Formant Class
#'
#' Praat Formant object with direct C++ module binding. Formant objects represent
#' the resonance frequencies of the vocal tract over time.
#'
#' @examples
#' \dontrun{
#' # Create formant object from sound
#' sound <- Sound$new(system.file("extdata", "example.wav", package = "speaker"))
#' formant <- sound$to_formant_burg(
#'   time_step = 0.01,
#'   max_number_of_formants = 5,
#'   maximum_formant = 5500,
#'   window_length = 0.025,
#'   pre_emphasis_from = 50
#' )
#' 
#' # Query formant values
#' f1_at_1s <- formant$get_value_at_time(formant_number = 1, time = 1.0, unit = "Hertz")
#' f2_at_1s <- formant$get_value_at_time(formant_number = 2, time = 1.0, unit = "Hertz")
#' 
#' # Get mean formant values
#' mean_f1 <- formant$get_mean(formant_number = 1, from_time = 0, to_time = 0, unit = "Hertz")
#' mean_f2 <- formant$get_mean(formant_number = 2, from_time = 0, to_time = 0, unit = "Hertz")
#' }
#'
#' @export
Formant <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Formant objects must be created from a Sound object using to_formant_burg() or to_formant_keepall()")
  }
  
  # Load module and create C++ object
  formant_mod <- get_module("formant_module")
  cpp_obj <- formant_mod$RFormant$new(.xptr)
  
  # Helper: unit code conversion
  unit_code <- function(unit) {
    unit <- match.arg(tolower(unit), c("hertz", "bark"))
    if (unit == "hertz") 0L else 1L
  }
  
  # Create object with methods
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,  # Keep raw pointer for legacy exports
    
    # Time domain methods
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },
    
    get_time_step = function() {
      cpp_obj$get_time_step()
    },
    
    get_min_num_formants = function() {
      cpp_obj$get_min_num_formants()
    },
    
    get_max_num_formants = function() {
      cpp_obj$get_max_num_formants()
    },
    
    # Query methods - formant values
    get_value_at_time = function(formant_number, time, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_value_at_time(as.integer(formant_number), time, unit_code(unit))
    },
    
    get_bandwidth_at_time = function(formant_number, time, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_bandwidth_at_time(as.integer(formant_number), time, unit_code(unit))
    },
    
    get_mean = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_mean(as.integer(formant_number), from_time, to_time, unit_code(unit))
    },
    
    get_standard_deviation = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_standard_deviation(as.integer(formant_number), from_time, to_time, unit_code(unit))
    },
    
    get_quantile = function(formant_number, quantile, from_time = 0, to_time = 0, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_quantile(as.integer(formant_number), quantile, from_time, to_time, unit_code(unit))
    },
    
    get_minimum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      cpp_obj$get_minimum(as.integer(formant_number), from_time, to_time, unit_code(unit), interpolate)
    },
    
    get_maximum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      cpp_obj$get_maximum(as.integer(formant_number), from_time, to_time, unit_code(unit), interpolate)
    },
    
    get_time_of_minimum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      cpp_obj$get_time_of_minimum(as.integer(formant_number), from_time, to_time, unit_code(unit), interpolate)
    },
    
    get_time_of_maximum = function(formant_number, from_time = 0, to_time = 0, unit = c("hertz", "bark"), interpolate = FALSE) {
      unit <- match.arg(unit)
      cpp_obj$get_time_of_maximum(as.integer(formant_number), from_time, to_time, unit_code(unit), interpolate)
    },
    
    # Export methods
    as_data_frame = function(max_formants = 5) {
      cpp_obj$as_data_frame(as.integer(max_formants))
    },
    
    save = function(filepath) {
      cpp_obj$save(filepath)
      invisible(obj)
    },
    
    # Advanced methods
    track = function(
      number_of_tracks = 3,
      ref_f1 = 550.0,
      ref_f2 = 1650.0,
      ref_f3 = 2750.0,
      ref_f4 = 3850.0,
      ref_f5 = 4950.0,
      frequency_cost = 1.0,
      bandwidth_cost = 1.0,
      transition_cost = 1.0
    ) {
      tracked_ptr <- .formant_tracker(
        .xptr,  # Use stored raw pointer
        as.integer(number_of_tracks),
        ref_f1, ref_f2, ref_f3, ref_f4, ref_f5,
        frequency_cost,
        bandwidth_cost,
        transition_cost
      )
      Formant(.xptr = tracked_ptr)
    },
    
    to_formantgrid = function() {
      grid_ptr <- .formantgrid_from_formant(.xptr)
      FormantGrid(.xptr = grid_ptr)
    },
    
    down_to_table = function(
      include_frame_numbers = TRUE,
      include_time = TRUE,
      time_decimals = 6,
      include_intensity = TRUE,
      intensity_decimals = 3,
      include_number_of_formants = TRUE,
      frequency_decimals = 3,
      include_bandwidths = TRUE
    ) {
      table_ptr <- .formant_down_to_table(
        .xptr,
        include_frame_numbers,
        include_time, as.integer(time_decimals),
        include_intensity, as.integer(intensity_decimals),
        include_number_of_formants, as.integer(frequency_decimals),
        include_bandwidths
      )
      Table(.xptr = table_ptr)
    },
    
    # Display
    print = function() {
      cat("<Praat Formant object>\n")
      cat(sprintf("  Number of frames: %d\n", cpp_obj$get_number_of_frames()))
      cat(sprintf("  Time step: %.6f s\n", cpp_obj$get_time_step()))
      cat(sprintf("  Min formants: %d\n", cpp_obj$get_min_num_formants()))
      cat(sprintf("  Max formants: %d\n", cpp_obj$get_max_num_formants()))
      invisible(obj)
    }
    
  ), class = c("Formant", "PraatObject"))
  
  obj
}

# S3 methods
#' @export
print.Formant <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Formant <- function(x, ..., max_formants = 5) {
  x$as_data_frame(max_formants)
}
