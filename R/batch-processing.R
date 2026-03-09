#' Batch Processing Utilities for Speaker Package
#'
#' @description
#' Functions for batch processing audio files, pairing Sound/TextGrid files,
#' and extracting measurements across multiple files. These utilities replace
#' the need for Praat's Strings and Table objects with R-idiomatic workflows.
#'
#' @name batch_processing
NULL

#' Batch Process Audio Files
#'
#' @description
#' Process multiple audio files with a custom function. This replaces Praat's
#' pattern of creating Strings objects and looping over files.
#'
#' @param directory Character path to directory containing audio files
#' @param pattern Regular expression pattern to match files (default: "\\\\.wav$")
#' @param func Function to apply to each file. Should accept a Sound object
#'   as first argument and return a named list or data frame row
#' @param recursive Logical, search directories recursively (default: FALSE)
#' @param parallel Logical, use parallel processing (default: FALSE)
#' @param ncores Integer, number of cores for parallel processing (default: NULL = all-1)
#' @param progress Logical, show progress bar (default: TRUE)
#' @param ... Additional arguments passed to func
#'
#' @return Data frame with results from all files
#'
#' @examples
#' \dontrun{
#' # Extract pitch statistics from all WAV files
#' results <- batch_process(
#'   directory = "audio_files/",
#'   pattern = "\\.wav$",
#'   func = function(sound) {
#'     pitch <- sound$to_pitch()
#'     list(
#'       mean_f0 = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
#'       sd_f0 = pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
#'     )
#'   }
#' )
#' }
#'
#' @export
batch_process <- function(directory, pattern = "\\.wav$", func, 
                         recursive = FALSE, parallel = FALSE, 
                         ncores = NULL, progress = TRUE, ...) {
  
  # Get file list
  files <- list.files(directory, pattern = pattern, 
                     full.names = TRUE, recursive = recursive)
  
  if (length(files) == 0) {
    warning("No files found matching pattern '", pattern, "' in ", directory)
    return(data.frame())
  }
  
  # Progress bar
  if (progress) {
    message("Processing ", length(files), " files...")
  }
  
  # Processing function
  process_file <- function(filepath) {
    tryCatch({
      sound <- Sound$new(filepath)
      result <- func(sound, ...)
      
      # Add filename to result
      if (is.list(result)) {
        result$file <- basename(filepath)
        result$path <- filepath
      }
      result
    }, error = function(e) {
      warning("Error processing ", filepath, ": ", e$message)
      list(file = basename(filepath), path = filepath, error = e$message)
    })
  }
  
  # Execute
  if (parallel) {
    if (!requireNamespace("parallel", quietly = TRUE)) {
      stop("Package 'parallel' is required for parallel processing")
    }
    if (is.null(ncores)) {
      ncores <- parallel::detectCores() - 1
    }
    results <- parallel::mclapply(files, process_file, mc.cores = ncores)
  } else {
    if (progress && requireNamespace("utils", quietly = TRUE)) {
      pb <- utils::txtProgressBar(min = 0, max = length(files), style = 3)
      results <- lapply(seq_along(files), function(i) {
        utils::setTxtProgressBar(pb, i)
        process_file(files[i])
      })
      close(pb)
    } else {
      results <- lapply(files, process_file)
    }
  }
  
  # Combine results
  do.call(rbind, lapply(results, function(x) {
    if (is.data.frame(x)) return(x)
    as.data.frame(x, stringsAsFactors = FALSE)
  }))
}

#' Pair Sound and TextGrid Files
#'
#' @description
#' Find matching Sound and TextGrid files in directories. This replaces Praat's
#' pattern of manually pairing files based on naming conventions.
#'
#' @param sound_dir Character path to directory containing audio files
#' @param textgrid_dir Character path to directory containing TextGrid files
#'   (default: same as sound_dir)
#' @param sound_pattern Pattern to match sound files (default: "\\\\.wav$")
#' @param textgrid_pattern Pattern to match TextGrid files (default: "\\\\.TextGrid$")
#' @param by Matching strategy: "basename" (default), "full", or a custom function
#' @param require_both Logical, only return pairs where both files exist (default: TRUE)
#'
#' @return Data frame with columns: sound_file, textgrid_file, basename
#'
#' @examples
#' \dontrun{
#' # Find all matching pairs
#' pairs <- pair_sound_textgrid(
#'   sound_dir = "audio/",
#'   textgrid_dir = "annotations/"
#' )
#'
#' # Process each pair
#' for (i in 1:nrow(pairs)) {
#'   sound <- Sound$new(pairs$sound_file[i])
#'   tg <- TextGrid$new(pairs$textgrid_file[i])
#'   # ... process ...
#' }
#' }
#'
#' @export
pair_sound_textgrid <- function(sound_dir, textgrid_dir = sound_dir,
                               sound_pattern = "\\.wav$",
                               textgrid_pattern = "\\.TextGrid$",
                               by = "basename",
                               require_both = TRUE) {
  
  # Get file lists
  sound_files <- list.files(sound_dir, pattern = sound_pattern, 
                           full.names = TRUE, recursive = FALSE)
  textgrid_files <- list.files(textgrid_dir, pattern = textgrid_pattern,
                              full.names = TRUE, recursive = FALSE)
  
  if (length(sound_files) == 0) {
    warning("No sound files found in ", sound_dir)
  }
  if (length(textgrid_files) == 0) {
    warning("No TextGrid files found in ", textgrid_dir)
  }
  
  # Extract basenames (without extension)
  if (by == "basename") {
    sound_base <- tools::file_path_sans_ext(basename(sound_files))
    tg_base <- tools::file_path_sans_ext(basename(textgrid_files))
    
    # Create data frame
    all_bases <- unique(c(sound_base, tg_base))
    pairs <- data.frame(
      basename = all_bases,
      sound_file = NA_character_,
      textgrid_file = NA_character_,
      stringsAsFactors = FALSE
    )
    
    # Match files
    for (i in seq_along(all_bases)) {
      base <- all_bases[i]
      sound_idx <- match(base, sound_base)
      tg_idx <- match(base, tg_base)
      
      if (!is.na(sound_idx)) {
        pairs$sound_file[i] <- sound_files[sound_idx]
      }
      if (!is.na(tg_idx)) {
        pairs$textgrid_file[i] <- textgrid_files[tg_idx]
      }
    }
    
    # Filter if needed
    if (require_both) {
      pairs <- pairs[!is.na(pairs$sound_file) & !is.na(pairs$textgrid_file), ]
    }
    
  } else if (by == "full") {
    # Match on full filename
    pairs <- data.frame(
      sound_file = sound_files,
      textgrid_file = textgrid_files[match(basename(sound_files), basename(textgrid_files))],
      basename = tools::file_path_sans_ext(basename(sound_files)),
      stringsAsFactors = FALSE
    )
    
    if (require_both) {
      pairs <- pairs[!is.na(pairs$textgrid_file), ]
    }
    
  } else if (is.function(by)) {
    # Custom matching function
    pairs <- by(sound_files, textgrid_files)
  } else {
    stop("Unknown matching strategy: ", by)
  }
  
  rownames(pairs) <- NULL
  pairs
}

#' Extract Custom Measurements from TextGrid Intervals
#'
#' @description
#' Extract acoustic measurements from intervals or points in TextGrid annotations.
#' This replaces complex Praat scripts that loop over TextGrid intervals.
#'
#' @param sound Sound object or path to sound file
#' @param textgrid TextGrid object or path to TextGrid file
#' @param tier Integer or character, tier number or name
#' @param measures Named list of measurement functions. Each function should
#'   accept (sound, tmin, tmax) and return a single value or named list
#' @param interval_filter Optional function to filter intervals, receives
#'   interval label and should return TRUE/FALSE
#' @param aggregate_by Character, how to aggregate: "interval" (default), 
#'   "label", or "tier"
#'
#' @return Data frame with measurements for each interval/point
#'
#' @examples
#' \dontrun{
#' # Extract pitch and intensity for each vowel interval
#' measurements <- extract_measurements_custom(
#'   sound = "recording.wav",
#'   textgrid = "recording.TextGrid",
#'   tier = "phones",
#'   measures = list(
#'     mean_f0 = function(snd, t1, t2) {
#'       pitch <- snd$extract_part(t1, t2, preserve_times = FALSE)$to_pitch()
#'       pitch$get_mean(0, 0, "hertz")
#'     },
#'     mean_intensity = function(snd, t1, t2) {
#'       intensity <- snd$extract_part(t1, t2, preserve_times = FALSE)$to_intensity()
#'       intensity$get_mean(0, 0)
#'     }
#'   ),
#'   interval_filter = function(label) label %in% c("a", "e", "i", "o", "u")
#' )
#' }
#'
#' @export
extract_measurements_custom <- function(sound, textgrid, tier, measures,
                                interval_filter = NULL,
                                aggregate_by = "interval") {
  
  # Load objects if needed
  if (is.character(sound)) {
    sound <- Sound$new(sound)
  }
  if (is.character(textgrid)) {
    textgrid <- TextGrid(path = textgrid)
  }
  
  # Get tier
  if (is.character(tier)) {
    tier_idx <- textgrid$get_tier_index(tier)
    if (tier_idx == 0) {
      stop("Tier '", tier, "' not found in TextGrid")
    }
  } else {
    tier_idx <- tier
  }
  
  # Check tier type
  is_interval_tier <- textgrid$is_interval_tier(tier_idx)
  
  # Get intervals/points
  if (is_interval_tier) {
    n_items <- textgrid$get_number_of_intervals(tier_idx)
    
    # Extract measurements
    results <- list()
    for (i in 1:n_items) {
      label <- textgrid$get_label_of_interval(tier_idx, i)
      
      # Filter if needed
      if (!is.null(interval_filter) && !interval_filter(label)) {
        next
      }
      
      tmin <- textgrid$get_start_time_of_interval(tier_idx, i)
      tmax <- textgrid$get_end_time_of_interval(tier_idx, i)
      
      # Extract part
      part <- sound$extract_part(tmin, tmax, preserve_times = FALSE)
      
      # Apply measurements
      row <- list(
        tier = tier_idx,
        interval = i,
        label = label,
        tmin = tmin,
        tmax = tmax,
        duration = tmax - tmin
      )
      
      for (measure_name in names(measures)) {
        measure_func <- measures[[measure_name]]
        tryCatch({
          value <- measure_func(part, 0, tmax - tmin)
          row[[measure_name]] <- value
        }, error = function(e) {
          warning("Error in measure '", measure_name, "' for interval ", i, ": ", e$message)
          row[[measure_name]] <- NA
        })
      }
      
      results[[length(results) + 1]] <- row
    }
    
  } else {
    # Point tier
    n_items <- textgrid$get_number_of_points(tier_idx)
    
    results <- list()
    for (i in 1:n_items) {
      label <- textgrid$get_label_of_point(tier_idx, i)
      
      # Filter if needed
      if (!is.null(interval_filter) && !interval_filter(label)) {
        next
      }
      
      time <- textgrid$get_time_of_point(tier_idx, i)
      
      # Apply measurements at point
      row <- list(
        tier = tier_idx,
        point = i,
        label = label,
        time = time
      )
      
      for (measure_name in names(measures)) {
        measure_func <- measures[[measure_name]]
        tryCatch({
          value <- measure_func(sound, time, time)
          row[[measure_name]] <- value
        }, error = function(e) {
          warning("Error in measure '", measure_name, "' for point ", i, ": ", e$message)
          row[[measure_name]] <- NA
        })
      }
      
      results[[length(results) + 1]] <- row
    }
  }
  
  # Convert to data frame
  df <- do.call(rbind, lapply(results, function(x) {
    as.data.frame(x, stringsAsFactors = FALSE)
  }))
  
  # Aggregate if needed
  if (aggregate_by == "label" && nrow(df) > 0) {
    # Group by label and aggregate
    measure_cols <- setdiff(names(df), c("tier", "interval", "point", "label", "tmin", "tmax", "time", "duration"))
    
    agg_list <- lapply(split(df, df$label), function(subset) {
      row <- list(label = subset$label[1])
      row$n <- nrow(subset)
      
      for (col in measure_cols) {
        if (is.numeric(subset[[col]])) {
          row[[paste0(col, "_mean")]] <- mean(subset[[col]], na.rm = TRUE)
          row[[paste0(col, "_sd")]] <- sd(subset[[col]], na.rm = TRUE)
        }
      }
      
      as.data.frame(row, stringsAsFactors = FALSE)
    })
    
    df <- do.call(rbind, agg_list)
    rownames(df) <- NULL
  }
  
  df
}

#' Create File List (Replaces Praat's Strings Object)
#'
#' @description
#' Create a file list similar to Praat's "Create Strings as file list".
#' Returns a simple character vector of file paths.
#'
#' @param directory Character path to directory
#' @param pattern Regular expression pattern to match files
#' @param full_names Logical, return full paths (default: TRUE)
#' @param recursive Logical, search recursively (default: FALSE)
#'
#' @return Character vector of file paths
#'
#' @examples
#' \dontrun{
#' # Equivalent to: Create Strings as file list: "list", "*.wav"
#' wav_files <- create_file_list("audio/", pattern = "\\.wav$")
#'
#' # Process each file
#' for (filepath in wav_files) {
#'   sound <- Sound$new(filepath)
#'   # ... process ...
#' }
#' }
#'
#' @export
create_file_list <- function(directory, pattern = NULL, 
                            full_names = TRUE, recursive = FALSE) {
  list.files(directory, pattern = pattern, 
            full.names = full_names, recursive = recursive)
}

# === Additional batch processing utilities ===

#' Pair Sound and TextGrid Files
#'
#' Find matching pairs of Sound and TextGrid files based on filename matching.
#' Equivalent to Praat's manual file pairing but automated.
#'
#' @param sound_dir Character. Directory containing sound files.
#' @param textgrid_dir Character. Directory containing TextGrid files (default: same as sound_dir).
#' @param sound_pattern Character. Pattern for sound files (default: "\\\\.wav$").
#' @param textgrid_pattern Character. Pattern for TextGrid files (default: "\\\\.TextGrid$").
#' @param by Character. Matching strategy: "basename" (default), "exact", or a custom function.
#' @param require_both Logical. Require both files to exist (default: TRUE).
#'
#' @return Data frame with columns: sound_file, textgrid_file, basename.
#'
#' @examples
#' \dontrun{
#' # Find all matching pairs
#' pairs <- pair_files(
#'   sound_dir = "~/audio/",
#'   textgrid_dir = "~/annotations/"
#' )
#'
#' # Process each pair
#' results <- lapply(seq_len(nrow(pairs)), function(i) {
#'   sound <- Sound$new(pairs$sound_file[i])
#'   textgrid <- TextGrid$new(pairs$textgrid_file[i])
#'   # ... analysis ...
#' })
#' }
#'
#' @export
pair_files <- function(sound_dir,
                      textgrid_dir = sound_dir,
                      sound_pattern = "\\.wav$",
                      textgrid_pattern = "\\.TextGrid$",
                      by = "basename",
                      require_both = TRUE) {
  
  # Get file lists
  sound_files <- list.files(sound_dir, pattern = sound_pattern, full.names = TRUE)
  textgrid_files <- list.files(textgrid_dir, pattern = textgrid_pattern, full.names = TRUE)
  
  # Extract basenames
  sound_basenames <- tools::file_path_sans_ext(basename(sound_files))
  tg_basenames <- tools::file_path_sans_ext(basename(textgrid_files))
  
  # Match files
  if (by == "basename") {
    # Use vectorized data.table join instead of loop
    sound_dt <- data.table::data.table(
      sound_file = sound_files,
      basename = sound_basenames
    )
    tg_dt <- data.table::data.table(
      textgrid_file = textgrid_files,
      basename = tg_basenames
    )
    
    if (require_both) {
      # Inner join - only matched pairs
      pairs <- data.table::merge.data.table(sound_dt, tg_dt, by = "basename", all = FALSE)
    } else {
      # Full outer join - all files
      pairs <- data.table::merge.data.table(sound_dt, tg_dt, by = "basename", all = TRUE)
    }
    
    data.table::setkey(pairs, basename)
  } else {
    stop("Only 'basename' matching is currently supported")
  }
  
  if (nrow(pairs) == 0) {
    warning("No matching pairs found")
  } else {
    message(sprintf("Found %d matching file pairs", nrow(pairs)))
  }
  
  pairs
}


#' Extract Measurements from Sound and TextGrid Pairs
#'
#' High-level function to extract acoustic measurements aligned with TextGrid intervals.
#' Automates the common Praat workflow of measuring formants/pitch at interval midpoints.
#'
#' @param sound Sound object or file path.
#' @param textgrid TextGrid object or file path.
#' @param tier Integer. Tier number to use for segmentation.
#' @param measurements Character vector. Measurements to extract: "pitch", "formants", "intensity", etc.
#' @param time_point Character. Where to measure: "midpoint" (default), "start", "end", or "mean".
#' @param pitch_params List. Parameters for pitch extraction (time_step, pitch_floor, pitch_ceiling).
#' @param formant_params List. Parameters for formant extraction (max_formants, max_frequency, etc.).
#' @param intensity_params List. Parameters for intensity extraction.
#'
#' @return Data frame with one row per interval, columns for label and requested measurements.
#'
#' @examples
#' \dontrun{
#' results <- extract_measurements(
#'   sound = "audio.wav",
#'   textgrid = "audio.TextGrid",
#'   tier = 1,
#'   measurements = c("pitch", "formants"),
#'   time_point = "midpoint"
#' )
#' }
#'
#' @export
extract_measurements <- function(sound,
                                textgrid,
                                tier = 1,
                                measurements = c("pitch", "formants", "intensity"),
                                time_point = c("midpoint", "start", "end", "mean"),
                                pitch_params = list(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600),
                                formant_params = list(time_step = 0.01, max_formants = 5, max_frequency = 5500,
                                                     window_length = 0.025, pre_emphasis = 50),
                                intensity_params = list(min_pitch = 100, time_step = 0, subtract_mean = TRUE)) {
  
  time_point <- match.arg(time_point)
  
  # Load objects if file paths provided
  if (is.character(sound)) {
    sound <- Sound$new(sound)
  }
  if (is.character(textgrid)) {
    textgrid <- TextGrid(path = textgrid)
  }
  
  # Create analysis objects
  pitch_obj <- NULL
  formant_obj <- NULL
  intensity_obj <- NULL
  
  if ("pitch" %in% measurements) {
    pitch_obj <- do.call(sound$to_pitch, pitch_params)
  }
  if ("formants" %in% measurements) {
    formant_obj <- do.call(sound$to_formant_burg, formant_params)
  }
  if ("intensity" %in% measurements) {
    intensity_obj <- do.call(sound$to_intensity, intensity_params)
  }
  
  # Get ALL intervals in single C++ call (returns index, label, start, end, duration)
  intervals <- textgrid_interval_statistics_batch(textgrid$get_xptr(), as.integer(tier))
  
  # Filter non-empty labels (vectorized)
  keep <- nzchar(intervals$label)
  if (!any(keep)) {
    return(NULL)
  }
  intervals <- intervals[keep, , drop = FALSE]
  n <- nrow(intervals)
  
  # Compute measurement times (vectorized)
  meas_times <- switch(time_point,
    midpoint = (intervals$start + intervals$end) / 2,
    start = intervals$start,
    end = intervals$end,
    mean = (intervals$start + intervals$end) / 2
  )
  
  # Build base result data.frame
  results <- data.frame(
    interval = intervals$index,
    label = intervals$label,
    start = intervals$start,
    end = intervals$end,
    duration = intervals$duration,
    stringsAsFactors = FALSE
  )
  
  # Batch pitch: single C++ call for all time points
  if (!is.null(pitch_obj)) {
    results$f0 <- .pitch_get_values_at_times(pitch_obj$.xptr, meas_times, unit = 0L, interpolate = TRUE)
  }
  
  # Batch formants: one C++ call per formant number
  if (!is.null(formant_obj)) {
    for (f_num in seq_len(formant_params$max_formants)) {
      results[[paste0("F", f_num)]] <- .formant_get_values_at_times(
        formant_obj$.xptr, meas_times, formant_number = as.integer(f_num), unit = 0L
      )
    }
  }
  
  # Batch intensity: single C++ call for all time points
  if (!is.null(intensity_obj)) {
    results$intensity <- .intensity_get_values_at_times(intensity_obj$.xptr, meas_times, interpolation = 1L)
  }
  
  results
}


#' Aggregate Measurements by Label
#'
#' Aggregate extracted measurements by interval label (e.g., phoneme, word).
#' Common workflow after extract_measurements().
#'
#' @param measurements Data frame from extract_measurements().
#' @param by Character. Column to group by (default: "label").
#' @param stats Character vector. Statistics to compute: "mean", "sd", "median", "min", "max", "n".
#'
#' @return Data frame with aggregated statistics.
#'
#' @examples
#' \dontrun{
#' vowel_stats <- aggregate_measurements(
#'   measurements = results,
#'   by = "label",
#'   stats = c("mean", "sd", "n")
#' )
#' }
#'
#' @export
aggregate_measurements <- function(measurements,
                                  by = "label",
                                  stats = c("mean", "sd", "n")) {
  
  if (!by %in% names(measurements)) {
    stop(sprintf("Column '%s' not found in measurements", by))
  }
  
  # Get numeric columns
  numeric_cols <- names(measurements)[vapply(measurements, is.numeric, logical(1))]
  
  # Aggregate
  agg_list <- list()
  
  for (col in numeric_cols) {
    for (stat in stats) {
      stat_fun <- switch(stat,
                        mean = mean,
                        sd = sd,
                        median = median,
                        min = min,
                        max = max,
                        n = length,
                        stop(sprintf("Unknown statistic: %s", stat)))
      
      agg_col <- aggregate(measurements[[col]], 
                          by = list(label = measurements[[by]]),
                          FUN = function(x) {
                            if (stat == "n") {
                              stat_fun(x)
                            } else {
                              stat_fun(x, na.rm = TRUE)
                            }
                          })
      
      col_name <- if (stat == "n") "n" else paste0(col, "_", stat)
      
      if (length(agg_list) == 0) {
        agg_list[[by]] <- agg_col$label
      }
      agg_list[[col_name]] <- agg_col$x
    }
  }
  
  as.data.frame(agg_list, stringsAsFactors = FALSE)
}
