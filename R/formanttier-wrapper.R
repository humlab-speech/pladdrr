#' @title Praat FormantTier Object
#' @description
#' Praat FormantTier object with direct C++ module binding for formant manipulation.
#'
#' @details
#' A FormantTier stores formant frequencies and bandwidths at discrete time points,
#' with interpolation between points. This allows for smooth formant contours
#' that can be used to filter sounds for vowel modification or resynthesis.
#'
#' ## Creating FormantTier Objects
#'
#' - `FormantTier(tmin, tmax)` - Create empty FormantTier
#' - `FormantTier$from_formant(formant)` - Convert from Formant object
#'
#' ## Querying
#'
#' - `$get_start_time()` - Start time in seconds
#' - `$get_end_time()` - End time in seconds
#' - `$get_duration()` - Duration in seconds
#' - `$get_number_of_points()` - Number of time points
#' - `$get_min_num_formants()` - Min formants across points
#' - `$get_max_num_formants()` - Max formants across points
#' - `$get_value_at_time(formant_number, time)` - Formant frequency (Hz)
#' - `$get_bandwidth_at_time(formant_number, time)` - Bandwidth (Hz)
#'
#' ## Transformation
#'
#' - `$filter_sound(sound, scale=TRUE)` - Filter sound through formants
#' - `$as_data_frame()` - Export to data frame
#' - `$save(path)` - Save to file
#'
#' @examples
#' \dontrun{
#' # Create from Formant analysis
#' sound <- Sound$read("vowel.wav")
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#'
#' # Query formant values
#' f1 <- ft$get_value_at_time(1, 0.5)  # F1 at 0.5s
#' f2 <- ft$get_value_at_time(2, 0.5)  # F2 at 0.5s
#'
#' # Filter a source sound
#' source <- Sound$create_tone(100, duration = 1.0)  # Buzz
#' vowel <- ft$filter_sound(source)
#' }
#'
#' @export
FormantTier <- function(tmin = 0, tmax = 1, .xptr = NULL) {
  
  # Handle creation modes
  if (!is.null(.xptr)) {
    # From existing C++ object
    ptr <- .xptr
  } else {
    # Create new empty tier
    ptr <- .formanttier_create(as.numeric(tmin), as.numeric(tmax))
  }
  
  tier_mod <- get_module("formanttier_module")
  cpp_obj <- tier_mod$RFormantTier$new(ptr)
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query Methods
    get_start_time = function() {
      cpp_obj$get_xmin()
    },
    
    get_end_time = function() {
      cpp_obj$get_xmax()
    },
    
    get_duration = function() {
      cpp_obj$get_duration()
    },
    
    get_number_of_points = function() {
      cpp_obj$get_number_of_points()
    },
    
    get_min_num_formants = function() {
      cpp_obj$get_min_num_formants()
    },
    
    get_max_num_formants = function() {
      cpp_obj$get_max_num_formants()
    },
    
    get_value_at_time = function(formant_number, time) {
      cpp_obj$get_value_at_time(as.integer(formant_number), as.numeric(time))
    },
    
    get_bandwidth_at_time = function(formant_number, time) {
      cpp_obj$get_bandwidth_at_time(as.integer(formant_number), as.numeric(time))
    },
    
    # Transformation
    filter_sound = function(sound, scale = TRUE) {
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      result_ptr <- cpp_obj$filter_sound_ptr(sound$.xptr, scale)
      Sound(.xptr = result_ptr)
    },
    
    # Export
    as_data_frame = function() {
      cpp_obj$as_data_frame()
    },
    
    save = function(path) {
      cpp_obj$save(as.character(path))
    },
    
    # Compatibility
    is_valid = function() {
      cpp_obj$is_valid()
    },
    
    get_ptr = function() {
      ptr
    },
    
    get_xptr = function() {
      ptr
    },
    
    # Print method
    print = function() {
      cat("<Praat FormantTier>\n")
      if (!cpp_obj$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat(sprintf("  Time domain: %.3f - %.3f seconds\n", 
                    cpp_obj$get_xmin(), cpp_obj$get_xmax()))
        cat("  Number of points:", cpp_obj$get_number_of_points(), "\n")
        nf_min <- cpp_obj$get_min_num_formants()
        nf_max <- cpp_obj$get_max_num_formants()
        if (nf_min == nf_max) {
          cat("  Formants per point:", nf_min, "\n")
        } else {
          cat("  Formants per point:", nf_min, "-", nf_max, "\n")
        }
      }
      invisible(obj)
    }
  ), class = c("FormantTier", "PraatObject"))
  
  obj
}

#' Create FormantTier from Formant
#' @param formant Formant object to convert
#' @return FormantTier object
#' @export
#' @examples
#' \dontrun{
#' sound <- Sound$read("vowel.wav")
#' formant <- sound$to_formant_burg()
#' ft <- FormantTier$from_formant(formant)
#' print(ft)
#' }
formanttier_from_formant <- function(formant) {
  if (!inherits(formant, "Formant")) {
    stop("formant must be a Formant object")
  }
  ptr <- .formanttier_from_formant(formant$.xptr)
  FormantTier(.xptr = ptr)
}

# Static method support
.formanttier_static_env <- new.env(parent = emptyenv())
.formanttier_static_env$from_formant <- formanttier_from_formant
.formanttier_static_env$new <- FormantTier

#' @exportS3Method
`$.formanttier_constructor` <- function(x, name) {
  .formanttier_static_env[[name]]
}

class(FormantTier) <- c("formanttier_constructor", "function")

#' @export
print.FormantTier <- function(x, ...) {
  x$print()
}

#' @export
as.data.frame.FormantTier <- function(x, ...) {
  x$as_data_frame()
}
