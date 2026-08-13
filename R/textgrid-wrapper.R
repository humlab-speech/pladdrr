# textgrid-wrapper.R - TextGrid object using shared dispatch table (pladdrr 4.8.33)
# Architecture: minimal list + $.TextGrid S3 dispatch → shared method env

#' @title Praat TextGrid Object
#' @description
#' R wrapper for a Praat TextGrid object for linguistic annotation.
#' Uses shared dispatch table for minimal memory per object.
#'
#' @details
#' TextGrids are the primary tool for linguistic annotation in Praat. They
#' contain one or more tiers, where each tier can be:
#'
#' \itemize{
#'   \item \code{IntervalTier}: consecutive time intervals with labels (e.g., phonemes, words)
#'   \item \code{PointTier} (TextTier): time points with labels (e.g., events, tones)
#' }
#'
#' @section Creating TextGrid objects:
#' \itemize{
#'   \item \code{TextGrid(path)} - read from file (Praat text or binary format)
#'   \item \code{textgrid_create(tmin, tmax, tier_names, point_tiers)} - create an empty grid
#' }
#'
#' @section Querying tiers:
#' \itemize{
#'   \item \code{get_number_of_tiers()} - number of tiers
#'   \item \code{get_tier_names()} - names of all tiers
#'   \item \code{tier_is_interval_tier(tier)} - check if a tier is an IntervalTier
#'   \item \code{tier_is_point_tier(tier)} - check if a tier is a PointTier
#' }
#'
#' @section IntervalTier operations:
#' \itemize{
#'   \item \code{get_number_of_intervals(tier)} - number of intervals in a tier
#'   \item \code{get_interval_text(tier, n)} - get the label of interval n
#'   \item \code{get_label_at_time(tier, time)} - get the label at a specific time
#'   \item \code{get_all_intervals(tier)} - get all intervals as a data.frame (fast)
#'   \item \code{extract_intervals_batch(tier, ...)} - extract matching intervals (fast)
#'   \item \code{extract_intervals_where(sound, tier, criterion, text, preserve_times)} - extract Sound intervals matching a text criterion
#'   \item \code{set_interval_text(tier, n, text)} - set the label of interval n
#'   \item \code{insert_boundary(tier, time)} - insert a new boundary
#'   \item \code{remove_boundary(tier, time)} - remove a boundary
#' }
#'
#' @section PointTier operations:
#' \itemize{
#'   \item \code{get_number_of_points(tier)} - number of points in a tier
#'   \item \code{get_point_text(tier, n)} - get the label of point n
#'   \item \code{insert_point(tier, time, mark)} - insert a new point
#'   \item \code{set_point_text(tier, n, text)} - set the label of point n
#'   \item \code{remove_point(tier, n)} - remove a point
#' }
#'
#' @section Tier management:
#' \itemize{
#'   \item \code{add_interval_tier(name)} - add a new IntervalTier
#'   \item \code{add_point_tier(name)} - add a new PointTier
#'   \item \code{remove_tier(tier)} - remove a tier
#'   \item \code{set_tier_name(tier, name)} - rename a tier
#'   \item \code{duplicate_tier(tier, new_name)} - duplicate a tier with a new name
#' }
#'
#' @section Export:
#' \itemize{
#'   \item \code{as_data_frame(tiers)} - convert to a long-format data frame
#'   \item \code{save(path)} - write to a file
#'   \item \code{extract_part(start, end)} - extract a time range
#' }
#'
#' @param path Path to a TextGrid file (Praat text or binary format). See the
#'   Creating TextGrid objects section for details.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   TextGrid object; set internally when a method returns a new TextGrid.
#' @return A \code{TextGrid} object with methods for tier and interval/point
#'   annotation access.
#'
#' @examples
#' # Create new TextGrid with one interval tier and one point tier
#' # (tier_names lists all tiers; point_tiers names the subset that are point tiers)
#' tg <- textgrid_create(0, 1, "words tones", "tones")
#' tg$get_tier_names()
#'
#' # Add boundaries and labels (IntervalTier)
#' tg$insert_boundary("words", 0.4)
#' tg$insert_boundary("words", 0.7)
#' tg$set_interval_text("words", 1, "hello")
#' tg$set_interval_text("words", 2, "world")
#'
#' # Add points and labels (PointTier)
#' tg$insert_point("tones", 0.2, "H*")
#' tg$insert_point("tones", 0.8, "L-L%")
#'
#' # Query
#' tg$get_number_of_intervals("words")
#' label <- tg$get_label_at_time("words", 0.5)
#'
#' # Export to R
#' df <- tg$as_data_frame()
#'
#' @name TextGrid
NULL

# ============================================================================
# Helper: resolve tier name/number
# ============================================================================

.textgrid_resolve_tier <- function(cpp_tg, tier) {
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

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.textgrid_methods <- new.env(hash = TRUE, parent = emptyenv())

# --- Basic Properties ---
.textgrid_methods$is_valid <- function(.self) .self$.cpp$is_valid()
.textgrid_methods$get_start_time <- function(.self) .self$.cpp$get_xmin()
.textgrid_methods$get_end_time <- function(.self) .self$.cpp$get_xmax()
.textgrid_methods$get_total_duration <- function(.self) .self$.cpp$get_duration()
.textgrid_methods$get_number_of_tiers <- function(.self) .self$.cpp$get_number_of_tiers()
.textgrid_methods$get_xmin <- function(.self) .self$.cpp$get_xmin()
.textgrid_methods$get_xmax <- function(.self) .self$.cpp$get_xmax()
.textgrid_methods$get_duration <- function(.self) .self$.cpp$get_duration()

# --- Tier Information ---
.textgrid_methods$get_tier_names <- function(.self) .self$.cpp$get_tier_names()
.textgrid_methods$get_tier_name <- function(.self, tier_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier_number)
  .self$.cpp$get_tier_name(tier_num)
}
.textgrid_methods$set_tier_name <- function(.self, tier, new_name) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$set_tier_name(tier_num, as.character(new_name))
  invisible(.self)
}
.textgrid_methods$tier_is_interval_tier <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$is_interval_tier(tier_num)
}
.textgrid_methods$tier_is_point_tier <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$is_point_tier(tier_num)
}

# --- IntervalTier Query ---
.textgrid_methods$get_number_of_intervals <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_number_of_intervals(tier_num)
}
.textgrid_methods$get_interval_start_time <- function(.self, tier, interval_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_interval_start_time(tier_num, as.integer(interval_number))
}
.textgrid_methods$get_interval_end_time <- function(.self, tier, interval_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_interval_end_time(tier_num, as.integer(interval_number))
}
.textgrid_methods$get_interval_text <- function(.self, tier, interval_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_interval_text(tier_num, as.integer(interval_number))
}
.textgrid_methods$get_interval_at_time <- function(.self, tier, time) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_interval_at_time(tier_num, as.numeric(time))
}
.textgrid_methods$get_label_at_time <- function(.self, tier, time) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_label_at_time(tier_num, as.numeric(time))
}
.textgrid_methods$get_all_intervals <- function(.self, tier = 1L) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  if (!.self$.cpp$is_interval_tier(tier_num)) {
    stop("Tier ", tier, " is a point tier, not an interval tier")
  }
  # Use batch C++ function for 10-50x speedup
  df <- textgrid_interval_statistics_batch(.self$.xptr, tier_num)
  data.frame(
    start = df$start,
    end = df$end,
    text = df$label,
    stringsAsFactors = FALSE
  )
}
.textgrid_methods$extract_intervals_batch <- function(.self, tier, comparison_type = "equals",
                                                      target_value = "", sound = NULL,
                                                      extract_sounds = FALSE) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  if (extract_sounds && is.null(sound)) {
    stop("sound argument required when extract_sounds = TRUE")
  }
  result <- textgrid_extract_intervals_batch(
    textgrid_xptr = .self$.xptr,
    sound_xptr = if (!is.null(sound)) sound$.xptr else NULL,
    tier_number = tier_num,
    comparison_type = comparison_type,
    target_value = target_value,
    extract_sounds = extract_sounds
  )
  if (extract_sounds && length(result$sounds) > 0) {
    result$sounds <- lapply(result$sounds, function(xptr) Sound(.xptr = xptr))
  }
  return(result)
}
.textgrid_methods$extract_intervals_where <- function(.self, sound, tier_number,
                                                       criterion = "is equal to",
                                                       text = "", preserve_times = FALSE) {
  if (!inherits(sound, "Sound")) stop("sound must be a Sound object")

  criterion_map <- c(
    "is equal to" = 1L, "is not equal to" = 2L, "contains" = 3L,
    "does not contain" = 4L, "starts with" = 5L, "does not start with" = 6L,
    "ends with" = 7L, "does not end with" = 8L,
    "contains a word equal to" = 9L, "does not contain a word equal to" = 10L,
    "matches regex" = 21L
  )
  which_criterion <- criterion_map[[criterion]]
  if (is.null(which_criterion)) {
    stop("Invalid criterion: '", criterion, "'. Must be one of: ",
         paste(names(criterion_map), collapse = ", "))
  }

  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier_number)

  result <- .textgrid_sound_extract_intervals_where(
    .self$.xptr, sound$.xptr, tier_num, which_criterion, text, preserve_times
  )

  lapply(result, function(xptr) Sound(.xptr = xptr))
}

# --- Batch/Vectorized ---
.textgrid_methods$get_labels_at_times <- function(.self, tier, times) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_labels_at_times(tier_num, as.numeric(times))
}
.textgrid_methods$set_interval_texts_batch <- function(.self, tier, interval_numbers, texts) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$set_interval_texts_batch(tier_num, as.integer(interval_numbers), as.character(texts))
  invisible(.self)
}
.textgrid_methods$get_all_intervals_fast <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_all_intervals(tier_num)
}
.textgrid_methods$get_all_points_fast <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_all_points(tier_num)
}

# --- IntervalTier Modification ---
.textgrid_methods$set_interval_text <- function(.self, tier, interval_number, text) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$set_interval_text(tier_num, as.integer(interval_number), as.character(text))
  invisible(.self)
}
.textgrid_methods$insert_boundary <- function(.self, tier, time) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$insert_boundary(tier_num, as.numeric(time))
  invisible(.self)
}
.textgrid_methods$remove_boundary <- function(.self, tier, time) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$remove_boundary_at_time(tier_num, as.numeric(time))
  invisible(.self)
}
.textgrid_methods$remove_boundary_at_time <- function(.self, tier, time) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$remove_boundary_at_time(tier_num, as.numeric(time))
  invisible(.self)
}

# --- PointTier Query ---
.textgrid_methods$get_number_of_points <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_number_of_points(tier_num)
}
.textgrid_methods$get_point_time <- function(.self, tier, point_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_point_time(tier_num, as.integer(point_number))
}
.textgrid_methods$get_point_text <- function(.self, tier, point_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$get_point_text(tier_num, as.integer(point_number))
}
.textgrid_methods$get_all_points <- function(.self, tier = 1L) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .textgrid_get_all_points(.self$.xptr, tier_num)
}

# --- PointTier Modification ---
.textgrid_methods$insert_point <- function(.self, tier, time, mark) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$insert_point(tier_num, as.numeric(time), as.character(mark))
  invisible(.self)
}
.textgrid_methods$set_point_text <- function(.self, tier, point_number, text) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$set_point_text(tier_num, as.integer(point_number), as.character(text))
  invisible(.self)
}
.textgrid_methods$remove_point <- function(.self, tier, point_number) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$remove_point(tier_num, as.integer(point_number))
  invisible(.self)
}

# --- Tier Management ---
.textgrid_methods$add_interval_tier <- function(.self, name) {
  .self$.cpp$add_interval_tier(as.character(name))
  invisible(.self)
}
.textgrid_methods$add_point_tier <- function(.self, name) {
  .self$.cpp$add_point_tier(as.character(name))
  invisible(.self)
}
.textgrid_methods$remove_tier <- function(.self, tier) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .self$.cpp$remove_tier(tier_num)
  invisible(.self)
}

# --- Transformations ---
.textgrid_methods$extract_part <- function(.self, start_time, end_time, preserve_times = TRUE) {
  ptr_result <- .self$.cpp$extract_part_ptr(
    as.numeric(start_time), as.numeric(end_time), as.logical(preserve_times)
  )
  TextGrid(.xptr = ptr_result)
}
.textgrid_methods$to_table <- function(.self) {
  ptr_result <- .self$.cpp$to_table_ptr()
  Table(.xptr = ptr_result)
}

# --- Export ---
.textgrid_methods$as_data_frame <- function(.self, tiers = NULL) {
  if (!is.null(tiers)) {
    df <- .self$.cpp$as_data_frame()
    if (is.numeric(tiers)) {
      df <- df[df$tier_number %in% tiers, ]
    } else if (is.character(tiers)) {
      df <- df[df$tier_name %in% tiers, ]
    }
    return(df)
  }
  .self$.cpp$as_data_frame()
}
.textgrid_methods$get_info <- function(.self) .self$.cpp$get_info()
.textgrid_methods$save <- function(.self, path) .self$.cpp$save(as.character(path))
.textgrid_methods$get_xptr <- function(.self) .self$.xptr

# --- Convenience ---
.textgrid_methods$duplicate_tier <- function(.self, tier, new_name) {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  .textgrid_duplicate_tier(.self$.xptr, tier_num, as.character(new_name))
  invisible(.self)
}
.textgrid_methods$get_intervals_where <- function(.self, tier, condition = "equals", text = "") {
  tier_num <- .textgrid_resolve_tier(.self$.cpp, tier)
  textgrid_get_intervals_where(.self, tier = tier_num, condition = condition, text = text)
}

# --- Print ---
.textgrid_methods$print <- function(.self) {
  cat("<Praat TextGrid>\n")
  cat(sprintf("  Time domain: [%.3f, %.3f] s (%.3f s)\n",
              .self$.cpp$get_xmin(), .self$.cpp$get_xmax(), .self$.cpp$get_duration()))
  cat(sprintf("  Tiers: %d\n", .self$.cpp$get_number_of_tiers()))
  tier_names <- .self$.cpp$get_tier_names()
  for (i in seq_along(tier_names)) {
    is_interval <- .self$.cpp$is_interval_tier(i)
    tier_type <- if (is_interval) "Interval" else "Point"
    n_items <- if (is_interval) {
      .self$.cpp$get_number_of_intervals(i)
    } else {
      .self$.cpp$get_number_of_points(i)
    }
    cat(sprintf("    %d. %s (%s, %d items)\n", i, tier_names[i], tier_type, n_items))
  }
  invisible(.self)
}

lockEnvironment(.textgrid_methods, bindings = TRUE)

# ============================================================================
# Constructor
# ============================================================================

#' @export
TextGrid <- function(path = NULL, .xptr = NULL) {
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
  tg_mod <- get_module("textgrid_module")
  cpp_tg <- tg_mod$RTextGrid$new(ptr)
  structure(list(.xptr = ptr, .cpp = cpp_tg), class = c("TextGrid", "PraatObject"))
}

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ TextGrid
#' @export
`$.TextGrid` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  if (name == ".pointer") return(.subset2(x, ".xptr"))
  method <- .textgrid_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

#' @export
print.TextGrid <- function(x, ...) x$print()

# ============================================================================
# Factory function
# ============================================================================

#' @title Create TextGrid
#' @description
#' Create a new empty TextGrid with specified tiers
#'
#' @param tmin Start time in seconds
#' @param tmax End time in seconds
#' @param tier_names Space-separated tier names (e.g., "phones words syllables")
#' @param point_tiers Space-separated names of tiers that should be PointTiers (default: all are IntervalTiers)
#' @seealso \code{\link{Sound}}, \code{\link{Pitch}}, \code{\link{Formant}}, \code{\link{PointProcess}}
#' @return A \code{TextGrid} object.
#' @export
#'
#' @examples
#' # Create TextGrid with 3 interval tiers
#' tg <- textgrid_create(0, 10, "phones words syllables")
#'
#' # Create TextGrid with mixed tier types
#' tg2 <- textgrid_create(0, 10, "phones tones", "tones")  # tones is PointTier
textgrid_create <- function(tmin, tmax, tier_names = "", point_tiers = "") {
  ptr <- .textgrid_create(
    as.numeric(tmin), as.numeric(tmax),
    as.character(tier_names), as.character(point_tiers)
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
#' @examples
#' create_fn <- TextGrid$create
#' tg <- create_fn(0, 1, "words")
#' @exportS3Method "$" textgrid_constructor
`$.textgrid_constructor` <- function(x, name) {
  val <- .textgrid_static_env[[name]]
  if (is.null(val)) {
    stop("TextGrid has no static method '", name, "'. Available: new, create")
  }
  val
}

# Assign class to enable $ operator
class(TextGrid) <- c("textgrid_constructor", "function")
