#' @title Praat TextGrid Object
#' @description
#' R6 class representing a Praat TextGrid object for linguistic annotation.
#' A TextGrid contains multiple tiers (IntervalTier or TextTier/PointTier) for
#' time-aligned transcription and segmentation.
#'
#' @details
#' TextGrids are the primary tool for linguistic annotation in Praat. They contain
#' one or more tiers, where each tier can be:
#' - **IntervalTier**: Consecutive time intervals with labels (e.g., phonemes, words)
#' - **PointTier** (TextTier): Time points with labels (e.g., events, tones)
#'
#' ## Creating TextGrid Objects
#'
#' - `TextGrid$new(path)` - Read from file (Praat text or binary format)
#' - `TextGrid$create(tmin, tmax, tier_names, point_tiers)` - Create empty grid
#'
#' ## Querying Tiers
#'
#' - `$get_number_of_tiers()` - Number of tiers
#' - `$get_tier_names()` - Names of all tiers
#' - `$tier_is_interval_tier(tier)` - Check if tier is IntervalTier
#' - `$tier_is_point_tier(tier)` - Check if tier is PointTier
#'
#' ## IntervalTier Operations
#'
#' - `$get_number_of_intervals(tier)` - Number of intervals in tier
#' - `$get_interval_text(tier, n)` - Get label of interval n
#' - `$get_label_at_time(tier, time)` - Get label at specific time
#' - `$set_interval_text(tier, n, text)` - Set label of interval n
#' - `$insert_boundary(tier, time)` - Insert new boundary
#' - `$remove_boundary(tier, time)` - Remove boundary
#'
#' ## PointTier Operations
#'
#' - `$get_number_of_points(tier)` - Number of points in tier
#' - `$get_point_text(tier, n)` - Get label of point n
#' - `$insert_point(tier, time, mark)` - Insert new point
#' - `$set_point_text(tier, n, text)` - Set label of point n
#' - `$remove_point(tier, n)` - Remove point
#'
#' ## Tier Management
#'
#' - `$add_interval_tier(name)` - Add new IntervalTier
#' - `$add_point_tier(name)` - Add new PointTier
#' - `$remove_tier(tier)` - Remove tier
#' - `$set_tier_name(tier, name)` - Rename a tier
#' - `$duplicate_tier(tier, new_name)` - Duplicate tier with new name
#'
#' ## Export
#'
#' - `$as_data_frame(tiers)` - Convert to long-format data frame
#' - `$save(path)` - Write to file
#' - `$extract_part(start, end)` - Extract time range
#'
#' @examples
#' \dontrun{
#' # Read existing TextGrid
#' tg <- TextGrid$new("annotation.TextGrid")
#' tg$get_tier_names()
#' tg$get_number_of_intervals("words")
#'
#' # Query specific intervals
#' label <- tg$get_label_at_time("words", 1.5)
#' word_text <- tg$get_interval_text("words", 5)
#'
#' # Create new TextGrid
#' tg <- TextGrid$create(0, 10, "phones words", "tones")
#'
#' # Add boundaries and labels (IntervalTier)
#' tg$insert_boundary("words", 1.5)
#' tg$insert_boundary("words", 3.2)
#' tg$set_interval_text("words", 1, "hello")
#' tg$set_interval_text("words", 2, "world")
#'
#' # Add points and labels (PointTier)
#' tg$insert_point("tones", 0.5, "H*")
#' tg$insert_point("tones", 2.3, "L-L%")
#'
#' # Export to R
#' df <- tg$as_data_frame()
#' df <- tg$as_data_frame(tiers = c(1, 3))  # Only tiers 1 and 3
#'
#' # Integration with Sound
#' sound <- Sound$new("audio.wav")
#' words <- tg$as_data_frame(tiers = "words")
#' for (i in 1:nrow(words)) {
#'   if (words$label[i] != "") {
#'     segment <- sound$extract_part(words$start_time[i], words$end_time[i])
#'     segment$save(paste0("word_", i, ".wav"))
#'   }
#' }
#'
#' # Save TextGrid
#' tg$save("output.TextGrid")
#' }
#'
#' @export
TextGrid <- R6::R6Class(
  "TextGrid",
  inherit = PraatObject,
  
  public = list(
    
    #' @description
    #' Create a TextGrid object from file or pointer
    #' @param path Path to TextGrid file (Praat text or binary format)
    #' @param .xptr Internal use only - external pointer to C++ TextGrid object
    #' @return A new TextGrid object
    initialize = function(path = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        super$initialize(.xptr)
      } else if (!is.null(path)) {
        if (!file.exists(path)) {
          stop("TextGrid file not found: ", path)
        }
        ptr <- .textgrid_read_from_file(path)
        super$initialize(ptr)
      } else {
        stop("Must provide either path or .xptr")
      }
    },
    
    # ========================================================================
    # Query Methods - Basic Properties
    # ========================================================================
    
    #' @description Get start time of TextGrid
    #' @return Start time in seconds
    get_start_time = function() {
      .textgrid_get_start_time(private$ptr)
    },
    
    #' @description Get end time of TextGrid
    #' @return End time in seconds
    get_end_time = function() {
      .textgrid_get_end_time(private$ptr)
    },
    
    #' @description Get total duration of TextGrid
    #' @return Duration in seconds
    get_total_duration = function() {
      .textgrid_get_total_duration(private$ptr)
    },
    
    #' @description Get number of tiers
    #' @return Number of tiers
    get_number_of_tiers = function() {
      .textgrid_get_number_of_tiers(private$ptr)
    },
    
    # ========================================================================
    # Query Methods - Tier Information
    # ========================================================================
    
    #' @description Get tier names
    #' @return Character vector of tier names
    get_tier_names = function() {
      .textgrid_get_tier_names(private$ptr)
    },
    
    #' @description Get name of specific tier
    #' @param tier_number Tier number (1-based) or tier name
    #' @return Tier name
    get_tier_name = function(tier_number) {
      tier_num <- private$resolve_tier_number(tier_number)
      .textgrid_get_tier_name(private$ptr, tier_num)
    },
    
    #' @description Check if tier is an IntervalTier
    #' @param tier Tier number (1-based) or tier name
    #' @return TRUE if IntervalTier, FALSE otherwise
    tier_is_interval_tier = function(tier) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_tier_is_interval_tier(private$ptr, tier_num)
    },
    
    #' @description Check if tier is a PointTier (TextTier)
    #' @param tier Tier number (1-based) or tier name
    #' @return TRUE if PointTier, FALSE otherwise
    tier_is_point_tier = function(tier) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_tier_is_point_tier(private$ptr, tier_num)
    },
    
    # ========================================================================
    # IntervalTier Query
    # ========================================================================
    
    #' @description Get number of intervals in tier
    #' @param tier Tier number (1-based) or tier name
    #' @return Number of intervals
    get_number_of_intervals = function(tier) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_number_of_intervals(private$ptr, tier_num)
    },
    
    #' @description Get start time of interval
    #' @param tier Tier number (1-based) or tier name
    #' @param interval_number Interval number (1-based)
    #' @return Start time in seconds
    get_interval_start_time = function(tier, interval_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_interval_start_time(private$ptr, tier_num, as.integer(interval_number))
    },
    
    #' @description Get end time of interval
    #' @param tier Tier number (1-based) or tier name
    #' @param interval_number Interval number (1-based)
    #' @return End time in seconds
    get_interval_end_time = function(tier, interval_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_interval_end_time(private$ptr, tier_num, as.integer(interval_number))
    },
    
    #' @description Get text/label of interval
    #' @param tier Tier number (1-based) or tier name
    #' @param interval_number Interval number (1-based)
    #' @return Interval label
    get_interval_text = function(tier, interval_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_interval_text(private$ptr, tier_num, as.integer(interval_number))
    },
    
    #' @description Get interval number at specific time
    #' @param tier Tier number (1-based) or tier name
    #' @param time Time in seconds
    #' @return Interval number (0 if time outside range)
    get_interval_at_time = function(tier, time) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_interval_at_time(private$ptr, tier_num, as.numeric(time))
    },
    
    #' @description Get label at specific time
    #' @param tier Tier number (1-based) or tier name
    #' @param time Time in seconds
    #' @return Label at that time (empty string if outside range)
    get_label_at_time = function(tier, time) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_label_at_time(private$ptr, tier_num, as.numeric(time))
    },
    
    # ========================================================================
    # IntervalTier Modification
    # ========================================================================
    
    #' @description Set text/label of interval
    #' @param tier Tier number (1-based) or tier name
    #' @param interval_number Interval number (1-based)
    #' @param text New label text
    #' @return Self (invisibly) for method chaining
    set_interval_text = function(tier, interval_number, text) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_set_interval_text(private$ptr, tier_num, as.integer(interval_number), as.character(text))
      invisible(self)
    },
    
    #' @description Insert boundary at time (splits interval)
    #' @param tier Tier number (1-based) or tier name
    #' @param time Time in seconds
    #' @return Self (invisibly) for method chaining
    insert_boundary = function(tier, time) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_insert_boundary(private$ptr, tier_num, as.numeric(time))
      invisible(self)
    },
    
    #' @description Remove boundary at time (merges intervals)
    #' @param tier Tier number (1-based) or tier name
    #' @param time Time in seconds
    #' @return Self (invisibly) for method chaining
    remove_boundary = function(tier, time) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_remove_boundary(private$ptr, tier_num, as.numeric(time))
      invisible(self)
    },
    
    # ========================================================================
    # PointTier Query
    # ========================================================================
    
    #' @description Get number of points in tier
    #' @param tier Tier number (1-based) or tier name
    #' @return Number of points
    get_number_of_points = function(tier) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_number_of_points(private$ptr, tier_num)
    },
    
    #' @description Get time of point
    #' @param tier Tier number (1-based) or tier name
    #' @param point_number Point number (1-based)
    #' @return Point time in seconds
    get_point_time = function(tier, point_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_point_time(private$ptr, tier_num, as.integer(point_number))
    },
    
    #' @description Get text/mark of point
    #' @param tier Tier number (1-based) or tier name
    #' @param point_number Point number (1-based)
    #' @return Point label
    get_point_text = function(tier, point_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_get_point_text(private$ptr, tier_num, as.integer(point_number))
    },
    
    # ========================================================================
    # PointTier Modification
    # ========================================================================
    
    #' @description Insert point with label
    #' @param tier Tier number (1-based) or tier name
    #' @param time Time in seconds
    #' @param mark Label/mark for the point
    #' @return Self (invisibly) for method chaining
    insert_point = function(tier, time, mark = "") {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_insert_point(private$ptr, tier_num, as.numeric(time), as.character(mark))
      invisible(self)
    },
    
    #' @description Set text/mark of point
    #' @param tier Tier number (1-based) or tier name
    #' @param point_number Point number (1-based)
    #' @param text New label text
    #' @return Self (invisibly) for method chaining
    set_point_text = function(tier, point_number, text) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_set_point_text(private$ptr, tier_num, as.integer(point_number), as.character(text))
      invisible(self)
    },
    
    #' @description Remove point
    #' @param tier Tier number (1-based) or tier name
    #' @param point_number Point number (1-based)
    #' @return Self (invisibly) for method chaining
    remove_point = function(tier, point_number) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_remove_point(private$ptr, tier_num, as.integer(point_number))
      invisible(self)
    },
    
    # ========================================================================
    # Tier Management
    # ========================================================================
    
    #' @description Add new IntervalTier
    #' @param name Name for the new tier
    #' @return Self (invisibly) for method chaining
    add_interval_tier = function(name) {
      .textgrid_add_interval_tier(private$ptr, as.character(name))
      invisible(self)
    },
    
    #' @description Add new PointTier (TextTier)
    #' @param name Name for the new tier
    #' @return Self (invisibly) for method chaining
    add_point_tier = function(name) {
      .textgrid_add_point_tier(private$ptr, as.character(name))
      invisible(self)
    },
    
    #' @description Remove tier
    #' @param tier Tier number (1-based) or tier name
    #' @return Self (invisibly) for method chaining
    remove_tier = function(tier) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_remove_tier(private$ptr, tier_num)
      invisible(self)
    },
    
    #' @description Set tier name
    #' @param tier Tier number (1-based) or tier name
    #' @param name New name for the tier
    #' @return Self (invisibly) for method chaining
    set_tier_name = function(tier, name) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_set_tier_name(private$ptr, tier_num, as.character(name))
      invisible(self)
    },
    
    #' @description Duplicate tier with new name
    #' @param tier Tier number (1-based) or tier name
    #' @param new_name Name for the duplicated tier
    #' @return Self (invisibly) for method chaining
    duplicate_tier = function(tier, new_name) {
      tier_num <- private$resolve_tier_number(tier)
      .textgrid_duplicate_tier(private$ptr, tier_num, as.character(new_name))
      invisible(self)
    },
    
    # ========================================================================
    # Extraction
    # ========================================================================
    
    #' @description Extract part of TextGrid
    #' @param start_time Start time in seconds
    #' @param end_time End time in seconds
    #' @param preserve_times Keep original times (TRUE) or shift to start at 0 (FALSE)
    #' @return New TextGrid object
    extract_part = function(start_time, end_time, preserve_times = TRUE) {
      ptr <- .textgrid_extract_part(
        private$ptr,
        as.numeric(start_time),
        as.numeric(end_time),
        as.logical(preserve_times)
      )
      TextGrid$new(.xptr = ptr)
    },
    
    # ========================================================================
    # Export
    # ========================================================================
    
    #' @description Convert to data frame
    #' @param tiers Tier numbers or names to export (default: all tiers)
    #' @return Data frame with columns: tier_name, tier_type, item_number, start_time, end_time, label
    as_data_frame = function(tiers = NULL) {
      if (is.null(tiers)) {
        .textgrid_to_data_frame(private$ptr)
      } else {
        tier_nums <- vapply(tiers, private$resolve_tier_number, integer(1))
        .textgrid_to_data_frame(private$ptr, as.integer(tier_nums))
      }
    },
    
    #' @description Save TextGrid to file
    #' @param path Output file path
    #' @return Self (invisibly)
    save = function(path) {
      .textgrid_save(private$ptr, as.character(path))
      invisible(self)
    },
    
    #' @description Print TextGrid summary
    #' @param ... Additional arguments (ignored)
    print = function(...) {
      cat("<Praat TextGrid>\n")
      cat(sprintf("  Time domain: %.3f to %.3f seconds (duration: %.3f s)\n",
                  self$get_start_time(), self$get_end_time(), self$get_total_duration()))
      cat(sprintf("  Number of tiers: %d\n", self$get_number_of_tiers()))
      
      tier_names <- self$get_tier_names()
      for (i in seq_along(tier_names)) {
        tier_type <- if (self$tier_is_interval_tier(i)) "IntervalTier" else "PointTier"
        if (tier_type == "IntervalTier") {
          n_items <- self$get_number_of_intervals(i)
        } else {
          n_items <- self$get_number_of_points(i)
        }
        cat(sprintf("  Tier %d: %s (%s, %d items)\n", i, tier_names[i], tier_type, n_items))
      }
      
      invisible(self)
    }
  ),
  
  private = list(
    #' @description Resolve tier name or number to tier number
    #' @param tier Tier number or name
    #' @return Tier number (integer)
    resolve_tier_number = function(tier) {
      if (is.numeric(tier)) {
        return(as.integer(tier))
      } else if (is.character(tier)) {
        tier_names <- self$get_tier_names()
        match_idx <- which(tier_names == tier)
        if (length(match_idx) == 0) {
          stop("Tier not found: ", tier)
        }
        return(as.integer(match_idx[1]))
      } else {
        stop("Tier must be numeric index or character name")
      }
    }
  )
)

#' @title Create TextGrid
#' @description
#' Create a new empty TextGrid with specified tiers
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param tier_names Space-separated tier names (e.g., "phones words syllables")
#' @param point_tiers Space-separated names of tiers that should be PointTiers (default: all are IntervalTiers)
#' @return TextGrid object
#' @export
#'
#' @examples
#' \dontrun{
#' # Create TextGrid with 3 interval tiers
#' tg <- TextGrid$create(0, 10, "phones words syllables")
#'
#' # Create TextGrid with mixed tier types
#' tg <- TextGrid$create(0, 10, "phones tones", "tones")  # tones is PointTier
#' }
TextGrid$create <- function(tmin, tmax, tier_names = "", point_tiers = "") {
  ptr <- .textgrid_create(
    as.numeric(tmin),
    as.numeric(tmax),
    as.character(tier_names),
    as.character(point_tiers)
  )
  TextGrid$new(.xptr = ptr)
}
