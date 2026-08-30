# TextGrid Batch Operations
# Part of Phase 3 Performance Enhancements (v2.0.7)
#
# High-performance batch operations for TextGrid interval extraction and analysis


# Resolve the interval text-comparison criterion to a type + target.

# Wrap extracted Sound external pointers into Sound objects.
.wrap_sound_xptrs <- function(xptrs) {
  lapply(xptrs, function(xptr) {
    if (is.null(xptr)) return(NULL)
    Sound(.xptr = xptr)
  })
}

.resolve_interval_criterion <- function(text_equals, text_contains, text_starts_with) {
  if (!is.null(text_equals)) list(type = "equals", target = as.character(text_equals))
  else if (!is.null(text_contains)) list(type = "contains", target = as.character(text_contains))
  else list(type = "starts_with", target = as.character(text_starts_with))
}

#' Extract Intervals Matching Criteria (Batch)
#'
#' Extract all intervals from a TextGrid tier that match specified text
#' criteria, in a single call instead of a manual R loop.
#'
#' @param textgrid A TextGrid object
#' @param sound A Sound object (optional, required if extract_sounds = TRUE)
#' @param tier Tier number (1-based) or tier name
#' @param text_equals Exact label match (e.g., "V" for voiced)
#' @param text_contains Substring match (e.g., "vowel")
#' @param text_starts_with Prefix match (e.g., "IPA_")
#' @param extract_sounds Logical. If TRUE, extract Sound parts for matched intervals
#'
#' @return List with components:
#'   - `indices`: Integer vector of matching interval indices
#'   - `labels`: Character vector of matching labels
#'   - `start_times`: Numeric vector of start times
#'   - `end_times`: Numeric vector of end times
#'   - `n_total`: Total number of intervals in tier
#'   - `n_matched`: Number of matching intervals
#'   - `sounds`: List of Sound objects (if extract_sounds = TRUE)
#'
#' @section How It Works:
#' A manual R loop makes one R<->C++ call per interval; this function does
#' the whole tier scan in a single C++ call.
#'
#' @section Comparison Types:
#' Specify exactly ONE comparison criterion:
#' - `text_equals`: Exact match (fastest)
#' - `text_contains`: Substring search
#' - `text_starts_with`: Prefix match
#'
#' @examples
#' # Create sound and a voiced/unvoiced TextGrid
#' sound <- Sound$create_tone(frequency = 150, duration = 1, sampling_rate = 16000)
#' pitch <- sound$to_pitch()
#' tg <- pitch$to_textgrid_vuv(0.02, 0.01)
#'
#' # Extract all voiced intervals (batch), with the matching Sound parts
#' result <- extract_textgrid_intervals(
#'   textgrid = tg,
#'   sound = sound,
#'   tier = 1,
#'   text_equals = "V",
#'   extract_sounds = TRUE
#' )
#' voiced_sounds <- result$sounds
#'
#' # Get interval durations without extracting sounds
#' result2 <- extract_textgrid_intervals(
#'   textgrid = tg,
#'   tier = 1,
#'   text_equals = "V",
#'   extract_sounds = FALSE
#' )
#' voiced_durations <- result2$end_times - result2$start_times
#'
#' @seealso
#' - [get_textgrid_labels_all()] to get all labels from a tier
#' - [get_textgrid_interval_stats()] to compute statistics for all intervals
#'
#' @export
extract_textgrid_intervals <- function(textgrid, sound = NULL, tier,
                                       text_equals = NULL,
                                       text_contains = NULL,
                                       text_starts_with = NULL,
                                       extract_sounds = FALSE) {
  
  tier <- .validate_textgrid_intervals_args(textgrid, sound, tier, extract_sounds)
  
  # Validate tier
  if (is.character(tier)) {
    tier <- textgrid$get_tier_number(tier)
  }
  if (!is.numeric(tier) || tier < 1) {
    stop("tier must be a positive integer or valid tier name")
  }
  
  # Validate sound if extracting
  if (extract_sounds) {
    if (is.null(sound)) {
      stop("sound argument required when extract_sounds = TRUE")
    }
    if (!inherits(sound, "Sound")) {
      stop("sound must be a Sound object")
    }
  }
  
  # Determine comparison type
  n_criteria <- sum(!is.null(text_equals), !is.null(text_contains), !is.null(text_starts_with))
  if (n_criteria == 0) {
    stop("Must specify one comparison criterion: text_equals, text_contains, or text_starts_with")
  }
  if (n_criteria > 1) {
    stop("Specify only ONE comparison criterion")
  }
  
  crit <- .resolve_interval_criterion(text_equals, text_contains, text_starts_with)
  comp_type <- crit$type
  target <- crit$target
  
  # Call C++ batch operation
  sound_xptr <- if (extract_sounds) sound$get_xptr() else NULL
  
  result <- textgrid_extract_intervals_batch(
    textgrid_xptr = textgrid$get_xptr(),
    sound_xptr = sound_xptr,
    tier_number = as.integer(tier),
    comparison_type = comp_type,
    target_value = target,
    extract_sounds = extract_sounds
  )
  
  # Wrap Sound xptrs in Sound objects if extracted
  if (extract_sounds && length(result$sounds) > 0) {
    result$sounds <- .wrap_sound_xptrs(result$sounds)
  }
  
  return(result)
}


#' Get All Labels from TextGrid Tier (Batch)
#'
#' Extract all interval labels from a tier in a single operation, instead of
#' calling `textgrid$get_interval_text()` repeatedly.
#'
#' @param textgrid A TextGrid object
#' @param tier Tier number (1-based) or tier name
#'
#' @return Character vector of all interval labels
#'
#' @examples
#' tg <- TextGrid$create(0, 1, "words")
#' tg$insert_boundary(1, 0.5)
#' tg$set_interval_text(1, 2, "hello")
#' labels <- get_textgrid_labels_all(tg, tier = 1)
#' table(labels)  # Frequency table of labels
#'
#' @export
get_textgrid_labels_all <- function(textgrid, tier) {
  if (!inherits(textgrid, "TextGrid")) {
    stop("textgrid must be a TextGrid object")
  }
  
  if (is.character(tier)) {
    tier <- textgrid$get_tier_number(tier)
  }
  
  textgrid_get_all_labels(textgrid$get_xptr(), as.integer(tier))
}


#' Get Interval Statistics for All Intervals (Batch)
#'
#' Compute statistics (start, end, duration, label) for all intervals in a
#' tier in a single call, instead of a manual loop. Returns a data frame
#' ready for analysis.
#'
#' @param textgrid A TextGrid object
#' @param tier Tier number (1-based) or tier name
#'
#' @return Data frame with columns:
#'   - `index`: Interval index (1-based)
#'   - `label`: Interval label
#'   - `start`: Start time (seconds)
#'   - `end`: End time (seconds)
#'   - `duration`: Duration (seconds)
#'
#' @examples
#' tg <- TextGrid$create(0, 1, "words")
#' tg$insert_boundary(1, 0.5)
#' tg$set_interval_text(1, 2, "hello")
#' stats <- get_textgrid_interval_stats(tg, tier = 1)
#'
#' # Analysis with base R
#' voiced <- stats[stats$label == "hello", ]
#' mean(voiced$duration)
#'
#' @export
get_textgrid_interval_stats <- function(textgrid, tier) {
  if (!inherits(textgrid, "TextGrid")) {
    stop("textgrid must be a TextGrid object")
  }
  
  if (is.character(tier)) {
    tier <- textgrid$get_tier_number(tier)
  }
  
  textgrid_interval_statistics_batch(textgrid$get_xptr(), as.integer(tier))
}


# Validate extract_textgrid_intervals arguments; returns resolved tier.
.validate_textgrid_intervals_args <- function(textgrid, sound, tier, extract_sounds) {
  if (!inherits(textgrid, "TextGrid")) stop("textgrid must be a TextGrid object")
  if (is.character(tier)) tier <- textgrid$get_tier_number(tier)
  if (!is.numeric(tier) || tier < 1) stop("tier must be a positive integer or valid tier name")
  if (extract_sounds) {
    if (is.null(sound)) stop("sound argument required when extract_sounds = TRUE")
    if (!inherits(sound, "Sound")) stop("sound must be a Sound object")
  }
  tier
}
