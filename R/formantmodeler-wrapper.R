#' @title Praat FormantModeler Object
#' @description
#' Robust formant trajectory modeling using polynomial fits with outlier detection.
#'
#' @details
#' FormantModeler provides polynomial modeling of formant trajectories over time.
#' It automatically identifies outliers and can find the optimal formant ceiling
#' for a given sound, making it useful for robust formant analysis in noisy speech.
#'
#' ## Creating FormantModeler Objects
#'
#' FormantModeler objects are created from Formant objects:
#' - `formant$to_formant_modeler()` - Create modeler from formant object
#'
#' Or directly from Sound with optimal ceiling:
#' - `sound$to_formant_optimal()` - Extract formants with optimal ceiling
#' - `sound$get_optimal_formant_ceiling()` - Get just the optimal ceiling
#'
#' ## Querying Properties
#'
#' - `$get_number_of_tracks()` - Number of formant tracks
#' - `$get_number_of_data_points()` - Number of data points
#' - `$get_number_of_parameters(track)` - Polynomial parameters for track
#' - `$get_coefficient_of_determination(from, to)` - R-squared for tracks
#' - `$get_standard_deviation(track)` - SD of residuals for track
#' - `$get_stress(...)` - Overall stress measure
#'
#' ## Value Queries
#'
#' - `$get_model_value_at_time(track, time)` - Modeled formant value
#' - `$get_data_point_value(track, index)` - Original measurement
#' - `$get_track_model_values(track)` - All modeled values for track
#'
#' ## Operations
#'
#' - `$fit()` - (Re)fit the model
#' - `$process_outliers(num_sigmas)` - Remove outliers beyond threshold
#' - `$to_formant()` - Convert back to Formant object
#'
#' @examples
#' \dontrun{
#' # Method 1: Create from existing Formant object
#' formant <- sound$to_formant_burg()
#' modeler <- formant$to_formant_modeler(
#'   tmin = 0, tmax = 0,
#'   num_tracks = 4,
#'   num_params = 5
#' )
#'
#' # Check model quality
#' r2 <- modeler$get_coefficient_of_determination(1, 4)
#' cat("R-squared:", r2, "\n")
#'
#' # Get smoothed formant values
#' f1_modeled <- modeler$get_track_model_values(1)
#' f2_modeled <- modeler$get_track_model_values(2)
#'
#' # Method 2: Direct with optimal ceiling search
#' result <- sound$to_formant_optimal(
#'   min_freq = 4500, max_freq = 6500,
#'   num_freq_steps = 11
#' )
#' formant <- result$formant
#' optimal_ceiling <- result$optimal_ceiling
#' cat("Optimal ceiling:", optimal_ceiling, "Hz\n")
#'
#' # Process outliers
#' cleaned <- modeler$process_outliers(num_sigmas = 3.0)
#' smoothed_formant <- cleaned$to_formant()
#' }
#'
#' @export
FormantModeler <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("FormantModeler objects must be created from a Formant object using formant$to_formant_modeler()")
  }

  fm_mod <- get_module("formantmodeler_module")
  cpp_obj <- fm_mod$RFormantModeler$new(.xptr)

  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = .xptr,

    # Query - Basic properties
    get_xmin = function() cpp_obj$get_xmin(),
    get_xmax = function() cpp_obj$get_xmax(),
    get_duration = function() cpp_obj$get_duration(),
    get_number_of_tracks = function() cpp_obj$get_number_of_tracks(),
    get_number_of_data_points = function() cpp_obj$get_number_of_data_points(),
    get_number_of_parameters = function(track) cpp_obj$get_number_of_parameters(as.integer(track)),
    get_number_of_invalid_data_points = function(track) cpp_obj$get_number_of_invalid_data_points(as.integer(track)),

    # Quality metrics
    get_coefficient_of_determination = function(from_track = 1, to_track = 0) {
      if (to_track == 0) to_track <- cpp_obj$get_number_of_tracks()
      cpp_obj$get_coefficient_of_determination(as.integer(from_track), as.integer(to_track))
    },

    get_r_squared = function(from_track = 1, to_track = 0) {
      obj$get_coefficient_of_determination(from_track, to_track)
    },

    get_standard_deviation = function(track) {
      cpp_obj$get_standard_deviation(as.integer(track))
    },

    get_residual_sum_of_squares = function(track) {
      cpp_obj$get_residual_sum_of_squares(as.integer(track))
    },

    get_stress = function(from_track = 1, to_track = 0, num_params_per_track = 5, power = 1.25) {
      if (to_track == 0) to_track <- cpp_obj$get_number_of_tracks()
      cpp_obj$get_stress(as.integer(from_track), as.integer(to_track),
                         as.integer(num_params_per_track), power)
    },

    get_weighted_mean = function(track) {
      cpp_obj$get_weighted_mean(as.integer(track))
    },

    # Value queries
    get_model_value_at_time = function(track, time) {
      cpp_obj$get_model_value_at_time(as.integer(track), as.numeric(time))
    },

    get_estimated_value_at_time = function(track, time) {
      cpp_obj$get_estimated_value_at_time(as.integer(track), as.numeric(time))
    },

    get_data_point_value = function(track, index) {
      cpp_obj$get_data_point_value(as.integer(track), as.integer(index))
    },

    get_data_point_sigma = function(track, index) {
      cpp_obj$get_data_point_sigma(as.integer(track), as.integer(index))
    },

    get_track_model_values = function(track) {
      cpp_obj$get_track_model_values(as.integer(track))
    },

    # Operations
    fit = function() {
      cpp_obj$fit()
      invisible(obj)
    },

    to_formant = function(estimate = TRUE, estimate_undefined = TRUE) {
      formant_ptr <- cpp_obj$to_formant_ptr(estimate, estimate_undefined)
      Formant(.xptr = formant_ptr)
    },

    process_outliers = function(num_sigmas = 3.0) {
      new_ptr <- cpp_obj$process_outliers_ptr(num_sigmas)
      FormantModeler(.xptr = new_ptr)
    },

    # Export
    as_data_frame = function() {
      cpp_obj$as_data_frame()
    },

    get_info = function() {
      cpp_obj$get_info()
    },

    # Utility
    get_xptr = function() .xptr,

    save = function(path) {
      cpp_obj$save(path)
      invisible(obj)
    },

    # Display
    print = function() {
      info <- cpp_obj$get_info()
      cat("<Praat FormantModeler>\n")
      cat(sprintf("  Time: %.3f - %.3f s (%.3f s)\n", info$xmin, info$xmax, info$xmax - info$xmin))
      cat(sprintf("  Tracks: %d, Data points: %d\n", info$n_tracks, info$n_data_points))
      cat("  Track R-squared: ")
      cat(sprintf("%.3f", info$track_r2), sep = ", ")
      cat("\n")
      invisible(obj)
    }

  ), class = c("FormantModeler", "PraatObject"))

  obj
}

#' @export
print.FormantModeler <- function(x, ...) {
  x$print()
}
