#' @title Praat Cochleagram Object
#' @description
#' R6 class representing a Praat Cochleagram object. Models basilar membrane
#' response using the Bark frequency scale (0-25.6 Bark).
#'
#' @details
#' A Cochleagram represents the output of a bank of auditory filters arranged
#' along the basilar membrane. Frequency is measured in Bark units:
#' - 0 Bark ≈ 0 Hz
#' - 13 Bark ≈ 1500 Hz (critical band center)
#' - 25.6 Bark ≈ 20,000 Hz
#'
#' ## Creating Cochleagram Objects
#'
#' - `sound$to_cochleagram(dt, df, window_length, forward_masking_time)` - Standard method
#' - `sound$to_cochleagram_edb(...)` - Ear-drum-brain model with synaptic processing
#'
#' ## Querying
#'
#' - `$get_value_at_time_and_frequency(time, freq_bark)` - Excitation at specific point
#' - `$get_time_from_column(i_col)` - Get time value for column index
#' - `$get_frequency_from_row(i_row)` - Get frequency value for row index
#'
#' ## Transformations
#'
#' - `$to_excitation(time)` - Extract excitation pattern at specific time
#' - `$get_difference(other, tmin, tmax)` - Compare two cochleagrams
#' - `$as_matrix()` - Export to R matrix (time × Bark frequency)
#'
#' @examples
#' \dontrun{
#' # Standard cochleagram
#' sound <- Sound$new("speech.wav")
#' cochlea <- sound$to_cochleagram(
#'   dt = 0.01,                    # Time step
#'   df = 0.1,                     # Frequency step (Bark)
#'   window_length = 0.03,         # Analysis window
#'   forward_masking_time = 0.03   # Temporal masking
#' )
#'
#' # Query excitation
#' excitation_1khz <- cochlea$get_value_at_time_and_frequency(0.5, 8.5) # ~1000 Hz
#'
#' # EDB model (more realistic but slower)
#' cochlea_edb <- sound$to_cochleagram_edb(
#'   dtime = 0.01,
#'   dfreq = 0.1,
#'   has_synapse = TRUE,
#'   replenishment_rate = 0.01,
#'   loss_rate = 0.1,
#'   return_rate = 0.05,
#'   reprocessing_rate = 0.01
#' )
#'
#' # Export and visualize
#' cochlea_data <- cochlea$as_matrix()
#' image(cochlea_data$values, 
#'       xlab = "Time (s)", 
#'       ylab = "Frequency (Bark)",
#'       main = "Cochleagram")
#'
#' # Compare two cochleagrams
#' sound1 <- Sound$new("normal.wav")
#' sound2 <- Sound$new("hearing_loss_simulation.wav")
#' cochlea1 <- sound1$to_cochleagram()
#' cochlea2 <- sound2$to_cochleagram()
#' difference <- cochlea1$get_difference(cochlea2, tmin = 0, tmax = 0)
#' }
#'
#' @export
Cochleagram <- R6::R6Class("Cochleagram",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Initialize a Cochleagram object (internal use)
    #' @param .xptr External pointer to Praat Cochleagram object
    initialize = function(.xptr) {
      if (missing(.xptr) || is.null(.xptr)) {
        stop("Cochleagram objects should be created via Sound$to_cochleagram() or Sound$to_cochleagram_edb()")
      }
      super$initialize(.xptr)
    },
    
    #' @description
    #' Get excitation value at specific time and frequency
    #' @param time Time in seconds
    #' @param freq_bark Frequency in Bark scale
    #' @return Excitation value
    get_value_at_time_and_frequency = function(time, freq_bark) {
      stopifnot(
        "time must be numeric" = is.numeric(time),
        "freq_bark must be numeric" = is.numeric(freq_bark)
      )
      .cochleagram_get_value_at_time_and_frequency(private$ptr, time, freq_bark)
    },
    
    #' @description
    #' Get time value for a specific column index
    #' @param i_col Column index (1-based)
    #' @return Time in seconds
    get_time_from_column = function(i_col) {
      stopifnot(
        "i_col must be numeric" = is.numeric(i_col),
        "i_col must be positive" = i_col > 0
      )
      .cochleagram_get_time_from_column(private$ptr, as.integer(i_col))
    },
    
    #' @description
    #' Get frequency value for a specific row index
    #' @param i_row Row index (1-based)
    #' @return Frequency in Bark
    get_frequency_from_row = function(i_row) {
      stopifnot(
        "i_row must be numeric" = is.numeric(i_row),
        "i_row must be positive" = i_row > 0
      )
      .cochleagram_get_frequency_from_row(private$ptr, as.integer(i_row))
    },
    
    #' @description
    #' Extract excitation pattern at specific time
    #' @param time Time in seconds
    #' @return Excitation object
    to_excitation = function(time) {
      stopifnot("time must be numeric" = is.numeric(time))
      xptr <- .cochleagram_to_excitation(private$ptr, time)
      Excitation$new(xptr)
    },
    
    #' @description
    #' Calculate difference between two cochleagrams
    #' @param other Another Cochleagram object
    #' @param tmin Minimum time (0 = use all)
    #' @param tmax Maximum time (0 = use all)
    #' @return Difference value
    get_difference = function(other, tmin = 0, tmax = 0) {
      stopifnot(
        "other must be a Cochleagram object" = inherits(other, "Cochleagram"),
        "tmin must be numeric" = is.numeric(tmin),
        "tmax must be numeric" = is.numeric(tmax)
      )
      .cochleagram_difference(private$ptr, other$.__enclos_env__$private$ptr, tmin, tmax)
    },
    
    #' @description
    #' Export cochleagram data as R matrix
    #' @return List containing matrix values, time vector, frequency vector, and domain info
    as_matrix = function() {
      .cochleagram_as_matrix(private$ptr)
    },
    
    #' @description
    #' Get cochleagram information
    #' @return List with time and frequency domain parameters
    get_info = function() {
      .cochleagram_get_info(private$ptr)
    },
    
    #' @description
    #' Print cochleagram information
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      info <- self$get_info()
      cat("Cochleagram object\n")
      cat(sprintf("  Time domain: %.3f to %.3f seconds\n", info$xmin, info$xmax))
      cat(sprintf("  Number of time samples: %d (dt = %.4f s)\n", info$nx, info$dx))
      cat(sprintf("  Frequency domain: %.1f to %.1f Bark\n", info$ymin, info$ymax))
      cat(sprintf("  Number of frequency bands: %d (df = %.3f Bark)\n", info$ny, info$dy))
      invisible(self)
    }
  )
)
