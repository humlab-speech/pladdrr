# Parallel batch processing functions
# pladdrr v2.3.0 - Phase 3 Performance Enhancement

# Per-worker C++ thread budget for nested parallelism.
#
# When N R workers each run Praat kernels that themselves spawn threads across
# all cores, the machine sees ~N*cores threads and thrashes (context-switch
# storms, higher power draw, often slower than either level alone). Divide the
# cores among the workers so total concurrency ~= detectCores(). NULL means
# auto; an explicit value is passed through unchanged.
.pladdrr_worker_thread_budget <- function(n_cores, threads_per_worker = NULL) {
  if (!is.null(threads_per_worker)) {
    return(max(1L, as.integer(threads_per_worker)))
  }
  total <- tryCatch(parallel::detectCores(), error = function(e) NA_integer_)
  if (is.na(total) || total < 1L) total <- n_cores
  max(1L, total %/% max(1L, as.integer(n_cores)))
}

#' Process Audio Files in Parallel
#'
#' @description
#' Process multiple audio files in parallel using multiple CPU cores.
#' Significantly speeds up batch analysis workflows.
#'
#' @param files Character vector. Paths to audio files
#' @param analysis_func Function. Analysis function to apply to each file.
#'   Should accept a Sound object and return results.
#' @param n_cores Integer. Number of CPU cores to use (default: parallel::detectCores() - 1)
#' @param threads_per_worker Integer or `NULL`. C++ threads each worker may use
#'   for Praat kernels. `NULL` (default) auto-divides cores among workers so
#'   total concurrency stays near the machine's core count, preventing
#'   oversubscription. Set `1` to force strictly single-threaded workers.
#' @param ... Additional arguments passed to analysis_func
#'
#' @return List of results from analysis_func, one per file
#'
#' @details
#' This function uses parallel processing to speed up batch analysis.
#' Each file is:
#' 1. Loaded as a Sound object
#' 2. Processed by analysis_func
#' 3. Results collected and returned
#'
#' **Performance:** 3-8x speedup on multi-core systems for I/O-bound tasks.
#'
#' @examples
#' \dontrun{
#' # Analyze pitch for multiple files in parallel
#' files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
#'
#' # Define analysis function
#' analyze_pitch <- function(sound) {
#'   pitch <- sound$to_pitch()
#'   list(
#'     mean_f0 = pitch$get_mean(0, 0, "hertz"),
#'     sd_f0 = pitch$get_standard_deviation(0, 0, "hertz")
#'   )
#' }
#'
#' # Run in parallel (uses n-1 cores by default)
#' results <- analyze_files_parallel(files, analyze_pitch)
#'
#' # With custom core count
#' results <- analyze_files_parallel(files, analyze_pitch, n_cores = 4)
#' }
#'
#' @export
analyze_files_parallel <- function(files, analysis_func, n_cores = NULL,
                                   threads_per_worker = NULL, ...) {
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel package required. Install with: install.packages('parallel')")
  }

  # Default to n-1 cores
  if (is.null(n_cores)) {
    n_cores <- max(1, parallel::detectCores() - 1)
  }

  # Single core fallback
  if (n_cores == 1) {
    message("Using single core (set n_cores > 1 for parallel processing)")
    return(lapply(files, function(f) {
      sound <- Sound(f)
      analysis_func(sound, ...)
    }))
  }

  # Parallel processing. Cap each worker's C++ threads so N workers x cores
  # threads don't oversubscribe the machine (see .pladdrr_worker_thread_budget).
  tpw <- .pladdrr_worker_thread_budget(n_cores, threads_per_worker)
  message(sprintf("Processing %d files using %d cores (%d thread(s)/worker)",
                  length(files), n_cores, tpw))

  # Use mclapply on Unix-like systems, parLapply on Windows
  if (.Platform$OS.type == "unix") {
    results <- parallel::mclapply(files, function(f) {
      pladdrr_threads(tpw)
      sound <- Sound(f)
      analysis_func(sound, ...)
    }, mc.cores = n_cores)
  } else {
    # Windows: use PSOCK cluster
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)

    # Load pladdrr on workers and export necessary objects
    parallel::clusterEvalQ(cl, library(pladdrr))
    parallel::clusterExport(cl, c("analysis_func", "tpw"), envir = environment())

    results <- parallel::parLapply(cl, files, function(f) {
      pladdrr_threads(tpw)
      sound <- Sound(f)
      analysis_func(sound, ...)
    })
  }

  results
}


#' Batch Process Sounds in Parallel
#'
#' @description
#' Apply analysis to pre-loaded Sound objects in parallel.
#' Use when sounds are already in memory.
#'
#' @param sounds List of Sound objects or external pointers
#' @param analysis_func Function. Analysis function to apply.
#'   Should accept a Sound object/pointer and return results.
#' @param n_cores Integer. Number of CPU cores (default: auto)
#' @param threads_per_worker Integer or `NULL`. C++ threads each worker may use
#'   for Praat kernels. `NULL` (default) auto-divides cores among workers to
#'   avoid oversubscription; set `1` to force single-threaded workers.
#' @param ... Additional arguments passed to analysis_func
#'
#' @return List of results
#'
#' @examples
#' \dontrun{
#' # Load sounds first
#' sounds <- lapply(files, Sound)
#'
#' # Process in parallel
#' results <- process_sounds_parallel(sounds, function(s) {
#'   pitch <- s$to_pitch()
#'   pitch$get_mean(0, 0, "hertz")
#' })
#' }
#'
#' @export
process_sounds_parallel <- function(sounds, analysis_func, n_cores = NULL,
                                    threads_per_worker = NULL, ...) {
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel package required")
  }

  if (is.null(n_cores)) {
    n_cores <- max(1, parallel::detectCores() - 1)
  }

  if (n_cores == 1) {
    return(lapply(sounds, analysis_func, ...))
  }

  # Cap each worker's C++ threads to avoid oversubscription (see
  # .pladdrr_worker_thread_budget). Wrap analysis_func so the cap is applied
  # inside each worker before any Praat kernel runs.
  tpw <- .pladdrr_worker_thread_budget(n_cores, threads_per_worker)
  capped_func <- function(s, ...) {
    pladdrr_threads(tpw)
    analysis_func(s, ...)
  }
  message(sprintf("Processing %d sounds using %d cores (%d thread(s)/worker)",
                  length(sounds), n_cores, tpw))

  if (.Platform$OS.type == "unix") {
    parallel::mclapply(sounds, capped_func, mc.cores = n_cores, ...)
  } else {
    cl <- parallel::makeCluster(n_cores)
    on.exit(parallel::stopCluster(cl), add = TRUE)
    parallel::clusterEvalQ(cl, library(pladdrr))
    parallel::clusterExport(cl, c("analysis_func", "tpw"), envir = environment())
    parallel::parLapply(cl, sounds, capped_func, ...)
  }
}


#' Parallel Pitch Extraction
#'
#' @description
#' Extract pitch from multiple files in parallel.
#' Convenience wrapper around analyze_files_parallel.
#'
#' @param files Character vector of file paths
#' @param n_cores Integer. Number of cores (default: auto)
#' @param pitch_floor Numeric. Minimum pitch in Hz (default: 75)
#' @param pitch_ceiling Numeric. Maximum pitch in Hz (default: 600)
#' @param time_step Numeric. Time step (default: 0, auto)
#'
#' @return List of Pitch objects
#'
#' @examples
#' \dontrun{
#' files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
#' pitches <- extract_pitch_parallel(files, n_cores = 4)
#' }
#'
#' @export
extract_pitch_parallel <- function(files, n_cores = NULL,
                                    pitch_floor = 75, pitch_ceiling = 600,
                                    time_step = 0) {
  analyze_files_parallel(files, function(sound) {
    sound$to_pitch(time_step = time_step, 
                   pitch_floor = pitch_floor,
                   pitch_ceiling = pitch_ceiling)
  }, n_cores = n_cores)
}


#' Parallel Formant Extraction
#'
#' @description
#' Extract formants from multiple files in parallel.
#'
#' @param files Character vector of file paths
#' @param n_cores Integer. Number of cores (default: auto)
#' @param time_step Numeric. Time step in seconds (default: 0.005)
#' @param max_formants Numeric. Max number of formants (default: 5)
#' @param max_frequency Numeric. Max frequency in Hz (default: 5500)
#'
#' @return List of Formant objects
#'
#' @examples
#' \dontrun{
#' files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)
#' formants <- extract_formant_parallel(files, n_cores = 4)
#' }
#'
#' @export
extract_formant_parallel <- function(files, n_cores = NULL,
                                      time_step = 0.005,
                                      max_formants = 5,
                                      max_frequency = 5500) {
  analyze_files_parallel(files, function(sound) {
    sound$to_formant(time_step = time_step,
                     max_formants = max_formants,
                     max_frequency = max_frequency)
  }, n_cores = n_cores)
}


#' Parallel Intensity Extraction
#'
#' @description
#' Extract intensity from multiple files in parallel.
#'
#' @param files Character vector of file paths
#' @param n_cores Integer. Number of cores (default: auto)
#' @param minimum_pitch Numeric. Minimum pitch for analysis (default: 100)
#' @param time_step Numeric. Time step (default: 0, auto)
#'
#' @return List of Intensity objects
#'
#' @export
extract_intensity_parallel <- function(files, n_cores = NULL,
                                        minimum_pitch = 100,
                                        time_step = 0) {
  analyze_files_parallel(files, function(sound) {
    sound$to_intensity(minimum_pitch = minimum_pitch,
                       time_step = time_step)
  }, n_cores = n_cores)
}


#' Benchmark Parallel vs Sequential Processing
#'
#' @description
#' Compare performance of parallel vs sequential processing.
#' Useful for determining optimal core count for your workload.
#'
#' @param files Character vector of files (use subset for quick test)
#' @param analysis_func Function to benchmark
#' @param core_counts Integer vector. Core counts to test (default: c(1, 2, 4))
#'
#' @return Data frame with timing results
#'
#' @examples
#' \dontrun{
#' files <- list.files("audio/", pattern = "\\.wav$", full.names = TRUE)[1:10]
#' 
#' # Test different core counts
#' results <- benchmark_parallel(
#'   files,
#'   function(s) s$to_pitch()$get_mean(0, 0, "hertz"),
#'   core_counts = c(1, 2, 4, 8)
#' )
#' print(results)
#' }
#'
#' @export
benchmark_parallel <- function(files, analysis_func, 
                                core_counts = c(1, 2, 4)) {
  if (!requireNamespace("parallel", quietly = TRUE)) {
    stop("parallel package required")
  }
  
  results <- data.frame(
    cores = integer(),
    time_sec = numeric(),
    speedup = numeric(),
    stringsAsFactors = FALSE
  )
  
  baseline_time <- NULL
  
  for (n_cores in core_counts) {
    cat(sprintf("Testing with %d core(s)...\n", n_cores))
    
    start_time <- Sys.time()
    analyze_files_parallel(files, analysis_func, n_cores = n_cores)
    elapsed <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
    
    if (is.null(baseline_time)) baseline_time <- elapsed
    speedup <- baseline_time / elapsed
    
    results <- rbind(results, data.frame(
      cores = n_cores,
      time_sec = elapsed,
      speedup = speedup
    ))
  }
  
  results
}
