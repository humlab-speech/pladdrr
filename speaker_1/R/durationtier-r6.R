#' @title Praat DurationTier Object
#' @description
#' R6 class representing a Praat DurationTier object. A DurationTier is a time-stamped
#' sequence of relative duration targets used for duration manipulation and speech synthesis.
#'
#' @details
#' DurationTiers are used in conjunction with Manipulation objects to modify the
#' duration/tempo of sounds. Values represent duration multiplication factors:
#' - 1.0 = normal speed
#' - 2.0 = half speed (doubled duration)
#' - 0.5 = double speed (halved duration)
#'
#' ## Creating DurationTier Objects
#'
#' - `DurationTier$new(tmin, tmax)` - Create empty DurationTier
#'
#' ## Querying
#'
#' - `$get_number_of_points()` - Number of duration points
#' - `$get_value_at_time(time)` - Interpolated duration factor at time
#' - `$get_value_at_index(index)` - Duration factor of specific point
#' - `$get_time_from_index(index)` - Time of specific point
#'
#' ## Modification
#'
#' - `$add_point(time, value)` - Add duration point (relative factor)
#' - `$remove_point(index)` - Remove point
#'
#' ## Export
#'
#' - `$as_data_frame()` - Convert to data frame
#' - `$save(path)` - Write to file
#'
#' @examples
#' \dontrun{
#' # Create duration tier
#' dur_tier <- DurationTier$new(0, 3)
#'
#' # Add duration modifications
#' dur_tier$add_point(0.5, 1.5)  # Slow down at 0.5s (1.5x duration)
#' dur_tier$add_point(1.5, 0.8)  # Speed up at 1.5s (0.8x duration)
#' dur_tier$add_point(2.5, 1.0)  # Normal speed at 2.5s
#'
#' # Query
#' factor_at_1s <- dur_tier$get_value_at_time(1.0)
#'
#' # Export
#' df <- dur_tier$as_data_frame()
#' dur_tier$save("modified.DurationTier")
#' }
#'
#' @export
DurationTier <- R6::R6Class(
  "DurationTier",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a DurationTier object
    #' @param tmin Start time (seconds)
    #' @param tmax End time (seconds)
    #' @param .xptr Internal use only - external pointer
    #' @return A new DurationTier object
    initialize = function(tmin = NULL, tmax = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(tmin) && !is.null(tmax)) {
        ptr <- .durationtier_create(as.numeric(tmin), as.numeric(tmax))
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
      .durationtier_get_start_time(private$ptr)
    },
    
    #' @description Get end time
    #' @return End time in seconds
    get_end_time = function() {
      .durationtier_get_end_time(private$ptr)
    },
    
    #' @description Get number of duration points
    #' @return Number of points
    get_number_of_points = function() {
      .durationtier_get_number_of_points(private$ptr)
    },
    
    #' @description Get time of specific point
    #' @param index Point index (1-based)
    #' @return Time in seconds
    get_time_from_index = function(index) {
      .durationtier_get_time_from_index(private$ptr, as.integer(index))
    },
    
    #' @description Get duration factor of specific point
    #' @param index Point index (1-based)
    #' @return Duration multiplication factor
    get_value_at_index = function(index) {
      .durationtier_get_value_at_index(private$ptr, as.integer(index))
    },
    
    #' @description Get interpolated duration factor at time
    #' @param time Time in seconds
    #' @return Duration multiplication factor (1.0 if undefined)
    get_value_at_time = function(time) {
      .durationtier_get_value_at_time(private$ptr, as.numeric(time))
    },
    
    # ========================================================================
    # Modification Methods
    # ========================================================================
    
    #' @description Add a duration point
    #' @param time Time in seconds
    #' @param value Duration multiplication factor
    #' @return Self (invisibly) for method chaining
    add_point = function(time, value) {
      .durationtier_add_point(private$ptr, as.numeric(time), as.numeric(value))
      invisible(self)
    },
    
    #' @description Remove a point
    #' @param index Point index (1-based)
    #' @return Self (invisibly) for method chaining
    remove_point = function(index) {
      .durationtier_remove_point(private$ptr, as.integer(index))
      invisible(self)
    },
    
    # ========================================================================
    # Export Methods
    # ========================================================================
    
    #' @description Convert to data frame
    #' @return Data frame with columns: time, duration_factor
    as_data_frame = function() {
      n_points <- self$get_number_of_points()
      if (n_points == 0) {
        return(data.frame(time = numeric(0), duration_factor = numeric(0)))
      }
      
      times <- numeric(n_points)
      factors <- numeric(n_points)
      
      for (i in seq_len(n_points)) {
        times[i] <- self$get_time_from_index(i)
        factors[i] <- self$get_value_at_index(i)
      }
      
      data.frame(time = times, duration_factor = factors)
    },
    
    #' @description Save to file
    #' @param path Output file path
    #' @return Self (invisibly)
    save = function(path) {
      .durationtier_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    # ========================================================================
    # Print Method
    # ========================================================================
    
    #' @description Print duration tier information
    print = function() {
      cat("<Praat DurationTier>\n")
      cat(sprintf("  Time domain: %.3f to %.3f s\n", 
                  self$get_start_time(), self$get_end_time()))
      n_points <- self$get_number_of_points()
      cat(sprintf("  Number of points: %d\n", n_points))
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
