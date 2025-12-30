#' @title Praat IntensityTier Object
#' @description
#' R6 class representing a Praat IntensityTier object. An IntensityTier is a time-stamped
#' sequence of intensity (dB) targets used for amplitude manipulation.
#'
#' @details
#' IntensityTiers contain discrete time-value pairs representing intensity in dB SPL.
#' They can be used to modify the amplitude envelope of sounds.
#'
#' ## Creating IntensityTier Objects
#'
#' - `IntensityTier$new(tmin, tmax)` - Create empty IntensityTier
#' - `intensity$down_to_intensity_tier()` - Extract from Intensity object
#'
#' ## Querying
#'
#' - `$get_number_of_points()` - Number of intensity points
#' - `$get_value_at_time(time)` - Interpolated intensity at time
#' - `$get_value_at_index(index)` - Intensity of specific point
#' - `$get_time_from_index(index)` - Time of specific point
#'
#' ## Modification
#'
#' - `$add_point(time, value)` - Add intensity point (dB)
#' - `$remove_point(index)` - Remove point
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to data frame
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Create from Intensity
#' sound <- Sound$new("audio.wav")
#' intensity <- sound$to_intensity()
#' int_tier <- intensity$down_to_intensity_tier()
#'
#' # Modify intensity
#' int_tier$add_point(1.0, 70)  # Set 70 dB at 1 second
#' int_tier$add_point(2.0, 80)  # Set 80 dB at 2 seconds
#'
#' # Query
#' db_at_1_5s <- int_tier$get_value_at_time(1.5)
#'
#' # Export
#' df <- int_tier$as_data_frame()
#' int_tier$save("modified.IntensityTier")
#' }
#'
#' @export
IntensityTier <- R6::R6Class(
  "IntensityTier",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create an IntensityTier object
    #' @param tmin Start time (seconds)
    #' @param tmax End time (seconds)
    #' @param .xptr Internal use only - external pointer
    #' @return A new IntensityTier object
    initialize = function(tmin = NULL, tmax = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(tmin) && !is.null(tmax)) {
        ptr <- .intensitytier_create(as.numeric(tmin), as.numeric(tmax))
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
      .intensitytier_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .intensitytier_get_end_time(private$ptr)
    },
    
    #' @description Get number of intensity points
    #' @return Number of points
    get_number_of_points = function() {
      .intensitytier_get_number_of_points(private$ptr)
    },
    
    #' @description Get time of specific point
    #' @param index Point index (1-based)
    #' @return Time in seconds
    get_time_from_index = function(index) {
      .intensitytier_get_time_from_index(private$ptr, as.integer(index))
    },
    
    #' @description Get intensity value of specific point
    #' @param index Point index (1-based)
    #' @return Intensity in dB SPL
    get_value_at_index = function(index) {
      .intensitytier_get_value_at_index(private$ptr, as.integer(index))
    },
    
    #' @description Get interpolated intensity at time
    #' @param time Time in seconds
    #' @return Intensity in dB SPL (NA if undefined)
    get_value_at_time = function(time) {
      .intensitytier_get_value_at_time(private$ptr, as.numeric(time))
    },
    
    #' @description Get mean intensity
    #' @param tmin Start time (default: tier start)
    #' @param tmax End time (default: tier end)
    #' @return Mean intensity in dB SPL
    get_mean = function(tmin = NULL, tmax = NULL) {
      if (is.null(tmin)) tmin <- self$get_start_time()
      if (is.null(tmax)) tmax <- self$get_end_time()
      .intensitytier_get_mean(private$ptr, as.numeric(tmin), as.numeric(tmax))
    },
    
    # ========================================================================
    # Modification Methods
    # ========================================================================
    
    #' @description Add an intensity point
    #' @param time Time in seconds
    #' @param value Intensity in dB SPL
    #' @return Self (invisibly) for method chaining
    add_point = function(time, value) {
      .intensitytier_add_point(private$ptr, as.numeric(time), as.numeric(value))
      invisible(self)
    },
    
    #' @description Remove a point
    #' @param index Point index (1-based)
    #' @return Self (invisibly) for method chaining
    remove_point = function(index) {
      .intensitytier_remove_point(private$ptr, as.integer(index))
      invisible(self)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Convert to data frame
    #' @return Data frame with columns: time, intensity_db
    as_data_frame = function() {
      n_points <- self$get_number_of_points()
      if (n_points == 0) {
        return(data.frame(time = numeric(0), intensity_db = numeric(0)))
      }
      
      times <- numeric(n_points)
      intensities <- numeric(n_points)
      
      for (i in seq_len(n_points)) {
        times[i] <- self$get_time_from_index(i)
        intensities[i] <- self$get_value_at_index(i)
      }
      
      data.frame(time = times, intensity_db = intensities)
    },
    
    #' @description Save to file
    #' @param path Output file path
    #' @return Self (invisibly)
    save = function(path) {
      .intensitytier_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print intensity tier information
    print = function() {
      cat("<Praat IntensityTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  self$get_start_time(), self$get_end_time()))
      n_points <- self$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
      if (n_points > 0) {
        mean_int <- self$get_mean()
        cat(sprintf("  Mean intensity: %.1f dB\n", mean_int))
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
