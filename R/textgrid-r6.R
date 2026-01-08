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
#' - `TextGrid(path)` - Read from file (Praat text or binary format)
#' - `textgrid_create(tmin, tmax, tier_names, point_tiers)` - Create empty grid
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
#' tg <- TextGrid("annotation.TextGrid")
#' tg$get_tier_names()
#' tg$get_number_of_intervals("words")
#'
#' # Query specific intervals
#' label <- tg$get_label_at_time("words", 1.5)
#' word_text <- tg$get_interval_text("words", 5)
#'
#' # Create new TextGrid
#' tg <- textgrid_create(0, 10, "phones words", "tones")
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
#' sound <- Sound("audio.wav")
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
TextGrid <- function(path = NULL, .xptr = NULL) {
  # Handle initialization
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else if (!is.null(path)) {
    if (!file.exists(path)) {
      stop("TextGrid file not found: ", path)
    }
    ptr <- .textgrid_read_from_file(path)
  } else {
    stop("Must provide either path or .xptr")
  }
  
  # Load Rcpp Module
  tg_mod <- get_module("textgrid_module")
  cpp_tg <- tg_mod$RTextGrid$new(ptr)
  
  # Helper to resolve tier name/number
  resolve_tier_number <- function(tier) {
    if (is.numeric(tier)) {
      return(as.integer(tier))
    } else if (is.character(tier)) {
      tier_names <- cpp_tg$get_tier_names()
      match_idx <- which(tier_names == tier)
      if (length(match_idx) == 0) {
        stop("Tier not found: ", tier)
      }
      return(as.integer(match_idx[1]))
    } else {
      stop("Tier must be numeric index or character name")
    }
  }
  
  # Create wrapper
  tg <- structure(list(
    .cpp = cpp_tg,
    .xptr = ptr,
    
    # === Basic Properties ===
    is_valid = function() cpp_tg$is_valid(),
    get_start_time = function() cpp_tg$get_xmin(),
    get_end_time = function() cpp_tg$get_xmax(),
    get_total_duration = function() cpp_tg$get_duration(),
    get_number_of_tiers = function() cpp_tg$get_number_of_tiers(),
    get_xmin = function() cpp_tg$get_xmin(),
    get_xmax = function() cpp_tg$get_xmax(),
    get_duration = function() cpp_tg$get_duration(),
    
    # === Tier Information ===
    get_tier_names = function() cpp_tg$get_tier_names(),
    get_tier_name = function(tier_number) {
      tier_num <- resolve_tier_number(tier_number)
      cpp_tg$get_tier_name(tier_num)
    },
    set_tier_name = function(tier, new_name) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$set_tier_name(tier_num, as.character(new_name))
      invisible(tg)
    },
    tier_is_interval_tier = function(tier) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$is_interval_tier(tier_num)
    },
    tier_is_point_tier = function(tier) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$is_point_tier(tier_num)
    },
    
    # === IntervalTier Query ===
    get_number_of_intervals = function(tier) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_number_of_intervals(tier_num)
    },
    get_interval_start_time = function(tier, interval_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_interval_start_time(tier_num, as.integer(interval_number))
    },
    get_interval_end_time = function(tier, interval_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_interval_end_time(tier_num, as.integer(interval_number))
    },
    get_interval_text = function(tier, interval_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_interval_text(tier_num, as.integer(interval_number))
    },
    get_interval_at_time = function(tier, time) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_interval_at_time(tier_num, as.numeric(time))
    },
    get_label_at_time = function(tier, time) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_label_at_time(tier_num, as.numeric(time))
    },
    get_all_intervals = function(tier) {
      tier_num <- resolve_tier_number(tier)
      .textgrid_get_all_intervals(ptr, tier_num)
    },
    
    # === IntervalTier Modification ===
    set_interval_text = function(tier, interval_number, text) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$set_interval_text(tier_num, as.integer(interval_number), as.character(text))
      invisible(tg)
    },
    insert_boundary = function(tier, time) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$insert_boundary(tier_num, as.numeric(time))
      invisible(tg)
    },
    remove_boundary = function(tier, time) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$remove_boundary_at_time(tier_num, as.numeric(time))
      invisible(tg)
    },
    remove_boundary_at_time = function(tier, time) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$remove_boundary_at_time(tier_num, as.numeric(time))
      invisible(tg)
    },
    
    # === PointTier Query ===
    get_number_of_points = function(tier) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_number_of_points(tier_num)
    },
    get_point_time = function(tier, point_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_point_time(tier_num, as.integer(point_number))
    },
    get_point_text = function(tier, point_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$get_point_text(tier_num, as.integer(point_number))
    },
    get_all_points = function(tier) {
      tier_num <- resolve_tier_number(tier)
      .textgrid_get_all_points(ptr, tier_num)
    },
    
    # === PointTier Modification ===
    insert_point = function(tier, time, mark) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$insert_point(tier_num, as.numeric(time), as.character(mark))
      invisible(tg)
    },
    set_point_text = function(tier, point_number, text) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$set_point_text(tier_num, as.integer(point_number), as.character(text))
      invisible(tg)
    },
    remove_point = function(tier, point_number) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$remove_point(tier_num, as.integer(point_number))
      invisible(tg)
    },
    
    # === Tier Management ===
    add_interval_tier = function(name) {
      cpp_tg$add_interval_tier(as.character(name))
      invisible(tg)
    },
    add_point_tier = function(name) {
      cpp_tg$add_point_tier(as.character(name))
      invisible(tg)
    },
    remove_tier = function(tier) {
      tier_num <- resolve_tier_number(tier)
      cpp_tg$remove_tier(tier_num)
      invisible(tg)
    },
    
    # === Transformations ===
    extract_part = function(start_time, end_time, preserve_times = TRUE) {
      ptr_result <- cpp_tg$extract_part_ptr(
        as.numeric(start_time),
        as.numeric(end_time),
        as.logical(preserve_times)
      )
      TextGrid(.xptr = ptr_result)
    },
    
    to_table = function() {
      ptr_result <- cpp_tg$to_table_ptr()
      Table(.xptr = ptr_result)
    },
    
    # === Export ===
    as_data_frame = function(tiers = NULL) {
      # If specific tiers requested, filter
      if (!is.null(tiers)) {
        # Get full dataframe first
        df <- cpp_tg$as_data_frame()
        # Filter by tier
        if (is.numeric(tiers)) {
          df <- df[df$tier_number %in% tiers, ]
        } else if (is.character(tiers)) {
          df <- df[df$tier_name %in% tiers, ]
        }
        return(df)
      }
      cpp_tg$as_data_frame()
    },
    
    get_info = function() cpp_tg$get_info(),
    save = function(path) cpp_tg$save(as.character(path)),
    get_xptr = function() ptr,
    
    # === Additional convenience methods (using old wrappers for now) ===
    duplicate_tier = function(tier, new_name) {
      tier_num <- resolve_tier_number(tier)
      .textgrid_duplicate_tier(ptr, tier_num, as.character(new_name))
      invisible(tg)
    },
    
    get_intervals_where = function(tier, condition = "equals", text = "") {
      tier_num <- resolve_tier_number(tier)
      textgrid_get_intervals_where(tg, tier = tier_num, condition = condition, text = text)
    },

    # === NEW: Batch methods for performance (v2.2.0) ===

    #' Get all intervals from a tier in single C++ call
    #' @param tier Tier number (1-based) or name
    #' @return data.frame with start, end, text columns
    get_all_intervals = function(tier = 1L) {
      tier_num <- resolve_tier_number(tier)
      if (!cpp_tg$is_interval_tier(tier_num)) {
        stop("Tier ", tier, " is a point tier, not an interval tier")
      }
      # Use batch C++ function for 10-50x speedup
      df <- textgrid_interval_statistics_batch(ptr, tier_num)
      # Return simplified format matching proposed API
      data.frame(
        start = df$start,
        end = df$end,
        text = df$label,
        stringsAsFactors = FALSE
      )
    },

    #' Get all points from a point tier in single C++ call
    #' @param tier Tier number (1-based) or name
    #' @return data.frame with time, text columns
    get_all_points = function(tier = 1L) {
      tier_num <- resolve_tier_number(tier)
      if (!cpp_tg$is_point_tier(tier_num)) {
        stop("Tier ", tier, " is an interval tier, not a point tier")
      }
      n <- cpp_tg$get_number_of_points(tier_num)
      if (n == 0) {
        return(data.frame(time = numeric(0), text = character(0), stringsAsFactors = FALSE))
      }
      # Build vectors in single pass using C++ module methods
      times <- numeric(n)
      texts <- character(n)
      for (i in seq_len(n)) {
        times[i] <- cpp_tg$get_point_time(tier_num, i)
        texts[i] <- cpp_tg$get_point_text(tier_num, i)
      }
      data.frame(time = times, text = texts, stringsAsFactors = FALSE)
    },

    print = function() {
      info <- cpp_tg$get_info()
      cat("<Praat TextGrid>\n")
      cat(sprintf("  Time domain: [%.3f, %.3f] s (%.3f s)\n", 
                  cpp_tg$get_xmin(), cpp_tg$get_xmax(), cpp_tg$get_duration()))
      cat(sprintf("  Tiers: %d\n", cpp_tg$get_number_of_tiers()))
      tier_names <- cpp_tg$get_tier_names()
      for (i in seq_along(tier_names)) {
        is_interval <- cpp_tg$is_interval_tier(i)
        tier_type <- if (is_interval) "Interval" else "Point"
        n_items <- if (is_interval) {
          cpp_tg$get_number_of_intervals(i)
        } else {
          cpp_tg$get_number_of_points(i)
        }
        cat(sprintf("    %d. %s (%s, %d items)\n", i, tier_names[i], tier_type, n_items))
      }
      invisible(tg)
    }
  ), class = c("TextGrid", "PraatObject"))
  
  tg
}

#' @export
print.TextGrid <- function(x, ...) x$print()

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
#' tg <- textgrid_create(0, 10, "phones words syllables")
#'
#' # Create TextGrid with mixed tier types
#' tg <- textgrid_create(0, 10, "phones tones", "tones")  # tones is PointTier
#' }
textgrid_create <- function(tmin, tmax, tier_names = "", point_tiers = "") {
  ptr <- .textgrid_create(
    as.numeric(tmin),
    as.numeric(tmax),
    as.character(tier_names),
    as.character(point_tiers)
  )
  TextGrid(.xptr = ptr)
}

# Static method support for TextGrid (enables TextGrid$new(), TextGrid$create())
.textgrid_static_env <- new.env(parent = emptyenv())
.textgrid_static_env$new <- TextGrid
.textgrid_static_env$create <- textgrid_create

#' $ method for TextGrid constructor (enables TextGrid$new(), TextGrid$create())
#' @param x The TextGrid constructor function
#' @param name Name of static method to access
#' @return The requested static method function
#' @exportS3Method $ textgrid_constructor
`$.textgrid_constructor` <- function(x, name) {
  val <- .textgrid_static_env[[name]]
  if (is.null(val)) {
    stop("TextGrid has no static method '", name, "'. Available: new, create")
  }
  val
}

# Assign class to enable $ operator
class(TextGrid) <- c("textgrid_constructor", "function")
