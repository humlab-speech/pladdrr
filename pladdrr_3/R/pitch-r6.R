# Pitch Object - Rcpp Module Wrapper
# Performance-optimized implementation using direct C++ binding
# Replaces R6 + [[Rcpp::export]] with Rcpp Modules for 2-3x speedup

#' Pitch Object
#'
#' @description
#' Fundamental frequency (F0) contour representation.
#' Uses Rcpp Modules for high-performance access to Praat's Pitch object.
#' 
#' **Architecture:** Direct C++ method calls via Rcpp Modules, eliminating
#' R6 dispatch overhead for 2-3x performance improvement.
#' 
#' @param .xptr External pointer to C++ Pitch object (internal use)
#' @return Pitch object with methods for querying pitch values and statistics
#' 
#' @examples
#' \dontrun{
#' sound <- Sound$new("voice.wav")
#' pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#' 
#' # Query methods
#' mean_f0 <- pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz")
#' min_f0 <- pitch$get_minimum(from_time = 0, to_time = 0, unit = "hertz")
#' n_voiced <- pitch$count_voiced_frames()
#' 
#' # Export
#' df <- as.data.frame(pitch)
#' }
#' 
#' @export
Pitch <- function(.xptr = NULL) {
  if (is.null(.xptr)) {
    stop("Pitch objects must be created from a Sound object using sound$to_pitch()")
  }
  
  # Load Rcpp Module
  pitch_mod <- get_module("pitch_module")
  if (is.null(pitch_mod)) {
    stop("pitch_module not available - package installation may be incomplete")
  }
  
  # Create C++ object
  cpp_obj <- pitch_mod$RPitch$new(.xptr)
  
  # Helper: Convert unit string to integer code for C++ API
  unit_code <- function(unit) {
    switch(tolower(unit),
      "hertz" = 0L, "hz" = 0L,
      "semitones" = 1L,
      "mel" = 2L,
      "erb" = 3L,
      stop("Unknown unit: ", unit, ". Use: hertz, semitones, mel, erb")
    )
  }
  
  # Create wrapper object with user-friendly method signatures
  obj <- structure(list(
    .cpp = cpp_obj,
    
    # Properties (direct C++ access)
    is_valid = function() cpp_obj$is_valid(),
    xmin = function() cpp_obj$get_xmin(),
    xmax = function() cpp_obj$get_xmax(),
    duration = function() cpp_obj$get_duration(),
    nx = function() cpp_obj$get_nx(),
    dx = function() cpp_obj$get_dx(),
    x1 = function() cpp_obj$get_x1(),
    ceiling = function() cpp_obj$get_ceiling(),
    
    # Time domain queries
    get_time_from_frame = function(frame_number) {
      cpp_obj$get_time_from_frame(as.integer(frame_number))
    },
    
    get_frame_from_time = function(time) {
      cpp_obj$get_frame_from_time(as.numeric(time))
    },
    
    get_number_of_frames = function() {
      cpp_obj$get_number_of_frames()
    },
    
    get_time_step = function() {
      cpp_obj$get_time_step()
    },
    
    # Pitch value queries (with unit conversion)
    get_value_at_time = function(time, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_value_at_time(as.numeric(time), unit_code(unit), as.logical(interpolate))
    },
    
    get_mean = function(from_time = 0, to_time = 0, unit = "hertz") {
      cpp_obj$get_mean(as.numeric(from_time), as.numeric(to_time), unit_code(unit))
    },
    
    get_standard_deviation = function(from_time = 0, to_time = 0, unit = "hertz") {
      cpp_obj$get_standard_deviation(as.numeric(from_time), as.numeric(to_time), unit_code(unit))
    },
    
    get_quantile = function(quantile, from_time = 0, to_time = 0, unit = "hertz") {
      cpp_obj$get_quantile(as.numeric(from_time), as.numeric(to_time), 
                          as.numeric(quantile), unit_code(unit))
    },
    
    get_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_minimum(as.numeric(from_time), as.numeric(to_time), 
                         unit_code(unit), as.logical(interpolate))
    },
    
    get_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_maximum(as.numeric(from_time), as.numeric(to_time), 
                         unit_code(unit), as.logical(interpolate))
    },
    
    get_time_of_minimum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_time_of_minimum(as.numeric(from_time), as.numeric(to_time), 
                                 unit_code(unit), as.logical(interpolate))
    },
    
    get_time_of_maximum = function(from_time = 0, to_time = 0, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_time_of_maximum(as.numeric(from_time), as.numeric(to_time), 
                                 unit_code(unit), as.logical(interpolate))
    },
    
    count_voiced_frames = function() {
      cpp_obj$count_voiced_frames()
    },
    
    get_strength_at_time = function(time, unit = "hertz", interpolate = TRUE) {
      cpp_obj$get_strength_at_time(as.numeric(time), unit_code(unit), as.logical(interpolate))
    },
    
    get_mean_strength = function(from_time = 0, to_time = 0, unit = "hertz") {
      cpp_obj$get_mean_strength(as.numeric(from_time), as.numeric(to_time), unit_code(unit))
    },
    
    get_intensity_at_time = function(time) {
      cpp_obj$get_intensity_at_time(as.numeric(time))
    },
    
    get_mean_intensity = function(from_time = 0, to_time = 0) {
      cpp_obj$get_mean_intensity(as.numeric(from_time), as.numeric(to_time))
    },
    
    # Transformation methods (return wrapped objects)
    to_point_process = function() {
      pp_ptr <- cpp_obj$to_point_process_ptr()
      PointProcess(.xptr = pp_ptr)
    },
    
    down_to_pitch_tier = function() {
      tier_ptr <- cpp_obj$down_to_pitch_tier_ptr()
      PitchTier(.xptr = tier_ptr)
    },
    
    to_textgrid_vuv = function() {
      tg_ptr <- cpp_obj$to_textgrid_vuv_ptr()
      TextGrid(.xptr = tg_ptr)
    },
    
    to_textgrid_silences = function(min_silent_duration = 0.1, min_sounding_duration = 0.1) {
      tg_ptr <- cpp_obj$to_textgrid_silences_ptr(min_silent_duration, min_sounding_duration)
      TextGrid(.xptr = tg_ptr)
    },
    
    # Export methods
    as_matrix = function() {
      cpp_obj$as_matrix()
    },
    
    as_data_frame = function(include_strength = FALSE, include_intensity = FALSE) {
      cpp_obj$as_data_frame(as.logical(include_strength), as.logical(include_intensity))
    },
    
    save = function(path) {
      cpp_obj$save(as.character(path))
      invisible(obj)
    },
    
    # Print method
    print = function() {
      cat("<Praat Pitch (Module)>\n")
      
      if (cpp_obj$is_valid()) {
        n_frames <- cpp_obj$get_number_of_frames()
        time_step <- cpp_obj$get_time_step()
        n_voiced <- cpp_obj$count_voiced_frames()
        
        cat(sprintf("  Duration: %.3f s\n", cpp_obj$get_duration()))
        cat(sprintf("  Frames: %d\n", n_frames))
        cat(sprintf("  Time step: %.4f s\n", time_step))
        cat(sprintf("  Voiced: %d (%.1f%%)\n", n_voiced, 100 * n_voiced / n_frames))
        
        tryCatch({
          mean_f0 <- cpp_obj$get_mean(0, 0, 0L)
          if (!is.na(mean_f0) && mean_f0 > 0) {
            min_f0 <- cpp_obj$get_minimum(0, 0, 0L, TRUE)
            max_f0 <- cpp_obj$get_maximum(0, 0, 0L, TRUE)
            sd_f0 <- cpp_obj$get_standard_deviation(0, 0, 0L)
            
            cat(sprintf("  Mean F0: %.1f Hz\n", mean_f0))
            cat(sprintf("  Range: %.1f - %.1f Hz\n", min_f0, max_f0))
            cat(sprintf("  SD: %.1f Hz\n", sd_f0))
          }
        }, error = function(e) {})
      } else {
        cat("  [Invalid object]\n")
      }
      
      invisible(obj)
    }
  ), class = c("Pitch", "PraatObject"))
  
  obj
}

#' @export
print.Pitch <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.Pitch <- function(x, row.names = NULL, optional = FALSE,
                                include_strength = FALSE, include_intensity = FALSE, ...) {
  x$as_data_frame(include_strength = include_strength, 
                  include_intensity = include_intensity)
}
