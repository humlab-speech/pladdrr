# formanttier-r6.R
# R6 class for Praat FormantTier objects

#' @title FormantTier Class
#' @description
#' R6 class for Praat FormantTier objects representing formant contours as points.
#' Used for formant manipulation and resynthesis.
#'
#' @details
#' A FormantTier stores formant frequencies and bandwidths at discrete time points,
#' with interpolation between points. This allows for smooth formant contours
#' that can be used to filter sounds for vowel modification or resynthesis.
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
FormantTier <- R6::R6Class(
  "FormantTier",
  inherit = PraatObject,

  public = list(
    #' @description Create FormantTier from parameters or external pointer
    #' @param tmin Start time (default 0)
    #' @param tmax End time (default 1)
    #' @param .xptr External pointer (for internal use)
    initialize = function(tmin = 0, tmax = 1, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else {
        ptr <- .formanttier_create(tmin, tmax)
        super$initialize(ptr)
      }
    },

    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      private$check_valid()
      .formanttier_get_start_time(private$ptr)
    },

    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      private$check_valid()
      .formanttier_get_end_time(private$ptr)
    },

    #' @description Get duration
    #' @return Duration in seconds
    get_duration = function() {
      self$get_end_time() - self$get_start_time()
    },

    #' @description Get number of points
    #' @return Number of points
    get_number_of_points = function() {
      private$check_valid()
      .formanttier_get_number_of_points(private$ptr)
    },

    #' @description Get minimum number of formants across points
    #' @return Minimum number of formants
    get_min_num_formants = function() {
      private$check_valid()
      .formanttier_get_min_num_formants(private$ptr)
    },

    #' @description Get maximum number of formants across points
    #' @return Maximum number of formants
    get_max_num_formants = function() {
      private$check_valid()
      .formanttier_get_max_num_formants(private$ptr)
    },

    #' @description Get formant value at time
    #' @param formant_number Formant number (1=F1, 2=F2, etc.)
    #' @param time Time in seconds
    #' @return Formant frequency in Hz
    get_value_at_time = function(formant_number, time) {
      private$check_valid()
      .formanttier_get_value_at_time(private$ptr, as.integer(formant_number), time)
    },

    #' @description Get formant bandwidth at time
    #' @param formant_number Formant number (1=F1, 2=F2, etc.)
    #' @param time Time in seconds
    #' @return Bandwidth in Hz
    get_bandwidth_at_time = function(formant_number, time) {
      private$check_valid()
      .formanttier_get_bandwidth_at_time(private$ptr, as.integer(formant_number), time)
    },

    #' @description Filter sound through this FormantTier
    #' @param sound Sound object to filter
    #' @param scale If TRUE (default), scale output amplitude
    #' @return Filtered Sound object
    filter_sound = function(sound, scale = TRUE) {
      private$check_valid()
      if (!inherits(sound, "Sound")) {
        stop("sound must be a Sound object")
      }
      if (scale) {
        ptr <- .formanttier_filter_sound(sound$get_ptr(), private$ptr)
      } else {
        ptr <- .formanttier_filter_sound_noscale(sound$get_ptr(), private$ptr)
      }
      Sound(.xptr = ptr)
    },

    #' @description Print method
    print = function() {
      cat("<Praat FormantTier>\n")
      if (!self$is_valid()) {
        cat("  [Invalid or deleted object]\n")
      } else {
        cat("  Time domain:", sprintf("%.3f - %.3f", self$get_start_time(), self$get_end_time()), "seconds\n")
        cat("  Number of points:", self$get_number_of_points(), "\n")
        nf_min <- self$get_min_num_formants()
        nf_max <- self$get_max_num_formants()
        if (nf_min == nf_max) {
          cat("  Formants per point:", nf_min, "\n")
        } else {
          cat("  Formants per point:", nf_min, "-", nf_max, "\n")
        }
      }
      invisible(self)
    }
  )
)

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
FormantTier$from_formant <- function(formant) {
  if (!inherits(formant, "Formant")) {
    stop("formant must be a Formant object")
  }
  ptr <- .formanttier_from_formant(formant$get_ptr())
  FormantTier$new(.xptr = ptr)
}
