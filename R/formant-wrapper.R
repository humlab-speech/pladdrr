#' Formant Class
#'
#' Praat Formant object with direct C++ module binding. Formant objects represent
#' the resonance frequencies of the vocal tract over time.
#'
#' @examples
#' \dontrun{
#' # Create formant object from sound
#' sound <- Sound$new(system.file("extdata", "example.wav", package = "pladdrr"))
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
    get_xmin = function() {
      cpp_obj$get_xmin()
    },
    
    get_xmax = function() {
      cpp_obj$get_xmax()
    },

    # Praat-compatible aliases
    get_start_time = function() {
      cpp_obj$get_xmin()
    },

    get_end_time = function() {
      cpp_obj$get_xmax()
    },

    get_duration = function() {
      cpp_obj$get_xmax() - cpp_obj$get_xmin()
    },

    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },
    
    get_time_step = function() {
      cpp_obj$get_time_step()
    },
    
    get_min_num_formants = function() {
      cpp_obj$get_min_num_formants()
    },
    # Praat-compatible alias
    get_minimum_number_of_formants = function() {
      cpp_obj$get_min_num_formants()
    },

    get_max_num_formants = function() {
      cpp_obj$get_max_num_formants()
    },

    # Query methods - formant values
    get_value_at_time = function(formant_number, time, unit = c("hertz", "bark"),
                                 interpolation = c("linear", "nearest")) {
      unit <- match.arg(unit)
      interpolation <- match.arg(interpolation)
      # Note: interpolation param is for API compatibility; Praat uses linear by default
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

    # === Batch/Vectorized Operations (20x speedup for formant analysis) ===
    get_times_vector = function() {
      cpp_obj$get_times_vector()
    },

    get_formant_track = function(formant_number, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_formant_track(as.integer(formant_number), unit_code(unit))
    },

    get_bandwidth_track = function(formant_number, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_bandwidth_track(as.integer(formant_number), unit_code(unit))
    },

    get_values_at_times = function(formant_number, times, unit = c("hertz", "bark"),
                                    interpolation = c("linear", "nearest")) {
      unit <- match.arg(unit)
      interpolation <- match.arg(interpolation)
      # interpolation param for API consistency; Praat's Formant_getValueAtTime
      # internally uses linear interpolation
      cpp_obj$get_values_at_times(
        as.integer(formant_number),
        as.numeric(times),
        unit_code(unit)
      )
    },

    # Get all formant values at a single time point
    # @param time Time in seconds
    # @param max_formants Maximum number of formants to query (default 5)
    # @param unit "hertz" or "bark"
    # @return Numeric vector of length max_formants (NA for missing formants)
    get_all_values_at_time = function(time, max_formants = 5,
                                       unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      vapply(seq_len(max_formants), function(i) {
        cpp_obj$get_value_at_time(as.integer(i), as.numeric(time), unit_code(unit))
      }, numeric(1))
    },

    get_all_formant_tracks = function(max_formants = 5, unit = c("hertz", "bark")) {
      unit <- match.arg(unit)
      cpp_obj$get_all_formant_tracks(as.integer(max_formants), unit_code(unit))
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

    # FormantModeler - robust formant tracking
    to_formant_modeler = function(tmin = 0.0, tmax = 0.0, num_tracks = 4, num_params = 5) {
      if (tmax == 0.0) tmax <- cpp_obj$get_xmax()
      fm_mod <- get_module("formantmodeler_module")
      fm_ptr <- fm_mod$Formant_to_FormantModeler(
        .xptr, tmin, tmax, as.integer(num_tracks), as.integer(num_params)
      )
      FormantModeler(.xptr = fm_ptr)
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
