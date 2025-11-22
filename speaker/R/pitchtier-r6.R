#' @title Praat PitchTier Object
#' @description
#' R6 class representing a Praat PitchTier object. A PitchTier is a time-stamped
#' sequence of pitch (F0) targets used for pitch manipulation and speech synthesis.
#'
#' @details
#' PitchTiers are used in conjunction with Manipulation objects to modify the
#' pitch contour of sounds. Unlike Pitch objects (which contain sampled data),
#' PitchTiers contain discrete time-value pairs that can be edited.
#'
#' ## Creating PitchTier Objects
#'
#' - `PitchTier$new(tmin, tmax)` - Create empty PitchTier
#' - `pitch$down_to_pitch_tier()` - Extract from Pitch object
#'
#' ## Querying
#'
#' - `$get_number_of_points()` - Number of pitch points
#' - `$get_value_at_time(time)` - Interpolated F0 at time
#' - `$get_value_at_index(index)` - F0 of specific point
#' - `$get_time_from_index(index)` - Time of specific point
#'
#' ## Modification
#'
#' - `$add_point(time, value)` - Add pitch point (Hz)
#' - `$remove_point(index)` - Remove point
#' - `$multiply_frequencies(factor)` - Scale all frequencies
#' - `$shift_frequencies(shift)` - Add to all frequencies (Hz)
#' - `$stylize(frequency_resolution)` - Simplify contour
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to data frame
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Create from Pitch
#' sound <- Sound$new("audio.wav")
#' pitch <- sound$to_pitch()
#' pitch_tier <- pitch$down_to_pitch_tier()
#'
#' # Modify pitch
#' pitch_tier$multiply_frequencies(1.5)  # Raise pitch 50%
#' pitch_tier$shift_frequencies(50)       # Add 50 Hz
#'
#' # Query
#' f0_at_1s <- pitch_tier$get_value_at_time(1.0)
#' n_points <- pitch_tier$get_number_of_points()
#'
#' # Export
#' df <- pitch_tier$as_data_frame()
#' pitch_tier$save("modified.PitchTier")
#' }
#'
#' @export
PitchTier <- R6::R6Class(
  "PitchTier",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a PitchTier object
    #' @param tmin Start time (seconds)
    #' @param tmax End time (seconds)
    #' @param .xptr Internal use only - external pointer
    #' @return A new PitchTier object
    initialize = function(tmin = NULL, tmax = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(tmin) && !is.null(tmax)) {
        ptr <- .pitchtier_create(as.numeric(tmin), as.numeric(tmax))
        super$initialize(ptr)
      } else {
        stop("Must provide either (tmin, tmax) or .xptr")
      }
    },
    
    # ========================================================================
    # Query Methods
    # ========================================================================
    
    #' @description Get start time
    #' @return Start time in seconds
    get_start_time = function() {
      .pitchtier_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .pitchtier_get_end_time(private$ptr)
    },
    
    #' @description Get number of pitch points
    #' @return Number of points
    get_number_of_points = function() {
      .pitchtier_get_number_of_points(private$ptr)
    },
    
    #' @description Get time of specific point
    #' @param index Point index (1-based)
    #' @return Time in seconds
    get_time_from_index = function(index) {
      .pitchtier_get_time_from_index(private$ptr, as.integer(index))
    },
    
    #' @description Get frequency value of specific point
    #' @param index Point index (1-based)
    #' @return Frequency in Hz
    get_value_at_index = function(index) {
      .pitchtier_get_value_at_index(private$ptr, as.integer(index))
    },
    
    #' @description Get interpolated frequency at time
    #' @param time Time in seconds
    #' @return Frequency in Hz (NA if undefined)
    get_value_at_time = function(time) {
      .pitchtier_get_value_at_time(private$ptr, as.numeric(time))
    },
    
    #' @description Get mean frequency
    #' @param tmin Start time (default: tier start)
    #' @param tmax End time (default: tier end)
    #' @return Mean frequency in Hz
    get_mean = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- self$get_start_time()
      if (is.null(tmax)) tmax <- self$get_end_time()
      .pitchtier_get_mean(private$ptr, as.numeric(tmin), as.numeric(tmax))
    },
    
    # ========================================================================
    # Modification Methods
    # ========================================================================
    
    #' @description Add a pitch point
    #' @param time Time in seconds
    #' @param value Frequency in Hz
    #' @return Self (invisibly) for method chaining
    add_point = function(time, value) {
      .pitchtier_add_point(private$ptr, as.numeric(time), as.numeric(value))
      invisible(self)
    },
    
    #' @description Remove a point
    #' @param index Point index (1-based)
    #' @return Self (invisibly) for method chaining
    remove_point = function(index) {
      .pitchtier_remove_point(private$ptr, as.integer(index))
      invisible(self)
    },
    
    #' @description Remove points between times
    #' @param tmin Start time
    #' @param tmax End time
    #' @return Self (invisibly) for method chaining
    remove_points_between = function(tmin, tmax) {
      .pitchtier_remove_points_between(private$ptr, as.numeric(tmin), as.numeric(tmax))
      invisible(self)
    },
    
    #' @description Multiply all frequencies by factor
    #' @param factor Multiplication factor
    #' @return Self (invisibly) for method chaining
    multiply_frequencies = function(factor) {
      .pitchtier_multiply_frequencies(private$ptr, as.numeric(factor))
      invisible(self)
    },
    
    #' @description Shift all frequencies by constant
    #' @param shift Frequency shift in Hz
    #' @return Self (invisibly) for method chaining
    shift_frequencies = function(shift) {
      .pitchtier_shift_frequencies(private$ptr, as.numeric(shift))
      invisible(self)
    },
    
    #' @description Stylize pitch tier (reduce number of points)
    #' @param frequency_resolution Maximum frequency difference for merging points (Hz)
    #' @param use_semitones Use semitone scale for resolution
    #' @return Self (invisibly) for method chaining
    stylize = function(frequency_resolution = 2.0, use_semitones = FALSE) {
      .pitchtier_stylize(private$ptr, as.numeric(frequency_resolution), 
                         as.logical(use_semitones))
      invisible(self)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Convert to data frame
    #' @return Data frame with columns: time, frequency
    as_data_frame = function() {
      n_points <- self$get_number_of_points()
      if (n_points == 0) {
        return(data.frame(time = numeric(0), frequency = numeric(0)))
      }
      
      times <- numeric(n_points)
      freqs <- numeric(n_points)
      
      for (i in seq_len(n_points)) {
        times[i] <- self$get_time_from_index(i)
        freqs[i] <- self$get_value_at_index(i)
      }
      
      data.frame(time = times, frequency = freqs)
    },
    
    #' @description Save to file
    #' @param path Output file path
    #' @return Self (invisibly)
    save = function(path) {
      .pitchtier_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print pitch tier information
    print = function() {
      cat("<Praat PitchTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  self$get_start_time(), self$get_end_time()))
      n_points <- self$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      if (n_points > 0) {
        mean_f0 <- self$get_mean()
        cat(sprintf("  Mean frequency: %.1f Hz\n", mean_f0))
      }
      invisible(self)
    }
  ),
  
  # ========================================================================
  # Active Bindings
  # ========================================================================
  active = list(
    #' @field tmin Start time (read-only)
    tmin = function() self$get_start_time(),
    
    #' @field tmax End time (read-only)
    tmax = function() self$get_end_time(),
    
    #' @field n_points Number of points (read-only)
    n_points = function() self$get_number_of_points()
  )
)
