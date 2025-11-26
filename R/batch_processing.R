#' Batch Process Audio Files
#'
#' Process multiple audio files with a user-defined function, similar to Praat's
#' file list iteration but using R's functional programming paradigm.
#'
#' @param directory Character. Directory containing audio files.
#' @param pattern Character. File pattern to match (default: "\\\\.wav$").
#' @param func Function. Processing function that takes a Sound object and returns results.
#' @param recursive Logical. Search recursively in subdirectories (default: FALSE).
#' @param parallel Logical. Use parallel processing (default: FALSE).
#' @param ncores Integer. Number of cores for parallel processing (default: detectCores() - 1).
#' @param progress Logical. Show progress bar (default: TRUE).
#' @param return_type Character. How to combine results: "list", "data.frame", or "bind_rows" (default: "data.frame").
#' @param ... Additional arguments passed to func.
#'
#' @return Results combined according to return_type parameter.
#'
#' @examples
#' \dontrun{
#' # Extract pitch statistics from all files
#' results <- batch_process(
#'   directory = "~/audio/",
#'   pattern = "\\.wav$",
#'   func = function(sound) {
#'     pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)
#'     data.frame(
#'       file = sound$get_name(),
#'       mean_f0 = pitch$get_mean(from_time = 0, to_time = 0, unit = "hertz"),
#'       sd_f0 = pitch$get_standard_deviation(from_time = 0, to_time = 0, unit = "hertz")
#'     )
#'   }
#' )
#' }
#'
#' @export
batch_process <- function(directory, 
                         pattern = "\\.wav$",
                         func,
                         recursive = FALSE,
                         parallel = FALSE,
                         ncores = parallel::detectCores() - 1,
                         progress = TRUE,
                         return_type = c("data.frame", "list", "bind_rows"),
                         ...) {
  return_type <- match.arg(return_type)
  
  # Get file list
  files <- list.files(directory, pattern = pattern, full.names = TRUE, recursive = recursive)
  
  if (length(files) == 0) {
    stop(sprintf("No files matching pattern '%s' found in directory '%s'", pattern, directory))
  }
  
  message(sprintf("Processing %d files...", length(files)))
  
  # Define processing wrapper
  process_file <- function(filepath) {
    tryCatch({
      sound <- Sound$new(filepath)
      result <- func(sound, ...)
      
      # Add file information if result is a data.frame
      if (is.data.frame(result) && !"file" %in% names(result)) {
        result$file <- basename(filepath)
      }
      
      result
    }, error = function(e) {
      warning(sprintf("Error processing %s: %s", basename(filepath), e$message))
      NULL
    })
  }
  
  # Process files
  if (parallel && requireNamespace("parallel", quietly = TRUE)) {
    if (progress) message("Using parallel processing with ", ncores, " cores")
    cl <- parallel::makeCluster(ncores)
    on.exit(parallel::stopCluster(cl))
    parallel::clusterExport(cl, c("Sound", "func"), envir = environment())
    results <- parallel::parLapply(cl, files, process_file)
  } else {
    if (progress && requireNamespace("progress", quietly = TRUE)) {
      pb <- progress::progress_bar$new(
        format = "[:bar] :percent :eta",
        total = length(files)
      )
      results <- lapply(files, function(f) {
        pb$tick()
        process_file(f)
      })
    } else {
      results <- lapply(files, process_file)
    }
  }
  
  # Remove NULL results (failed processing)
  results <- Filter(Negate(is.null), results)
  
  # Combine results
  if (return_type == "list") {
    return(results)
  } else if (return_type == "data.frame" || return_type == "bind_rows") {
    tryCatch({
      do.call(rbind, results)
    }, error = function(e) {
      warning("Could not combine results into data.frame: ", e$message)
      return(results)
    })
  }
}


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
    pairs <- data.frame(
      sound_file = character(),
      textgrid_file = character(),
      basename = character(),
      stringsAsFactors = FALSE
    )
    
    # Find matches
    for (i in seq_along(sound_files)) {
      snd_base <- sound_basenames[i]
      tg_idx <- match(snd_base, tg_basenames)
      
      if (!is.na(tg_idx)) {
        pairs <- rbind(pairs, data.frame(
          sound_file = sound_files[i],
          textgrid_file = textgrid_files[tg_idx],
          basename = snd_base,
          stringsAsFactors = FALSE
        ))
      } else if (!require_both) {
        pairs <- rbind(pairs, data.frame(
          sound_file = sound_files[i],
          textgrid_file = NA_character_,
          basename = snd_base,
          stringsAsFactors = FALSE
        ))
      }
    }
    
    # Add unmatched TextGrids if require_both = FALSE
    if (!require_both) {
      unmatched_tg <- setdiff(tg_basenames, pairs$basename)
      for (tg_base in unmatched_tg) {
        tg_idx <- match(tg_base, tg_basenames)
        pairs <- rbind(pairs, data.frame(
          sound_file = NA_character_,
          textgrid_file = textgrid_files[tg_idx],
          basename = tg_base,
          stringsAsFactors = FALSE
        ))
      }
    }
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
    textgrid <- TextGrid$new(textgrid)
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
  
  # Get intervals
  n_intervals <- textgrid$get_number_of_intervals(tier_number = tier)
  
  # Extract measurements
  results <- lapply(seq_len(n_intervals), function(i) {
    label <- textgrid$get_label_of_interval(tier_number = tier, interval_number = i)
    
    # Skip empty labels
    if (label == "") {
      return(NULL)
    }
    
    start <- textgrid$get_start_time(tier_number = tier, interval_number = i)
    end <- textgrid$get_end_time(tier_number = tier, interval_number = i)
    
    # Determine measurement time
    meas_time <- switch(time_point,
                       midpoint = (start + end) / 2,
                       start = start,
                       end = end,
                       mean = (start + end) / 2)  # mean is same as midpoint for time
    
    row <- data.frame(
      interval = i,
      label = label,
      start = start,
      end = end,
      duration = end - start,
      stringsAsFactors = FALSE
    )
    
    # Add pitch
    if (!is.null(pitch_obj)) {
      f0 <- pitch_obj$get_value_at_time(time = meas_time, unit = "hertz", interpolation = "linear")
      row$f0 <- f0
    }
    
    # Add formants
    if (!is.null(formant_obj)) {
      for (f_num in 1:formant_params$max_formants) {
        f_val <- formant_obj$get_value_at_time(formant_number = f_num, time = meas_time,
                                                unit = "hertz", interpolation = "linear")
        row[[paste0("F", f_num)]] <- f_val
      }
    }
    
    # Add intensity
    if (!is.null(intensity_obj)) {
      int_val <- intensity_obj$get_value_at_time(time = meas_time, interpolation = "cubic")
      row$intensity <- int_val
    }
    
    row
  })
  
  # Combine results
  do.call(rbind, Filter(Negate(is.null), results))
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
