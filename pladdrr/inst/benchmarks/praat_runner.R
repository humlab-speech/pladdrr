# Praat Script Execution Helper for Benchmarking
# Based on superassp approach with timing isolation

#' Execute a Praat script and measure only execution time
#' 
#' This function runs a Praat script via command line, ensuring that only
#' the actual script execution time is measured, not Praat startup overhead.
#' 
#' @param praat_exe Path to Praat executable (default: macOS location)
#' @param script_code Praat script code to execute
#' @param args Named list of arguments to pass to script
#' @param return_type "info-window" for Info window output, "last-argument" for last arg
#' @param measure_only_execution If TRUE, wraps script to exclude startup time
#' @return List with timing info and results
run_praat_script <- function(praat_exe = "/Applications/Praat.app/Contents/MacOS/Praat",
                              script_code,
                              args = NULL,
                              return_type = c("info-window", "last-argument"),
                              measure_only_execution = TRUE) {
  
  return_type <- match.arg(return_type)
  
  # Create temporary directory for this execution
  temp_dir <- tempfile()
  dir.create(temp_dir, recursive = TRUE)
  on.exit(unlink(temp_dir, recursive = TRUE), add = TRUE)
  
  # If measuring only execution, wrap script with timing
  if (measure_only_execution) {
    # Wrap script to measure execution time excluding startup
    wrapped_script <- paste0(
      "# Timing wrapper - captures only execution time\n",
      "stopwatch\n",  # Start timing after Praat has loaded
      script_code, "\n",
      "execution_time = stopwatch\n",
      "writeInfoLine: \"EXEC_TIME:\", fixed$(execution_time, 6)\n"
    )
  } else {
    wrapped_script <- script_code
  }
  
  # Write script to temp file
  script_file <- file.path(temp_dir, "script.praat")
  writeLines(wrapped_script, script_file)
  
  # Build arguments
  script_args <- character(0)
  if (!is.null(args)) {
    script_args <- vapply(args, shQuote, character(1))
  }
  
  # Execute Praat script
  start_time <- Sys.time()
  output <- system2(
    praat_exe,
    c("--utf8", "--run", shQuote(script_file), script_args),
    stdout = TRUE,
    stderr = TRUE
  )
  total_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  # Parse execution time if available
  execution_time <- total_time
  if (measure_only_execution && !is.null(output)) {
    exec_line <- grep("^EXEC_TIME:", output, value = TRUE)
    if (length(exec_line) > 0) {
      execution_time <- as.numeric(sub("EXEC_TIME:\\s*", "", exec_line))
    }
  }
  
  # Return results
  list(
    output = output,
    total_time = total_time,
    execution_time = execution_time,
    script_file = script_file
  )
}

#' Benchmark a Praat script operation
#' 
#' @param praat_exe Path to Praat executable
#' @param script_code Praat script code
#' @param args Named list of arguments
#' @param iterations Number of iterations
#' @param warmup Number of warmup iterations
#' @return Timing statistics
benchmark_praat <- function(praat_exe = "/Applications/Praat.app/Contents/MacOS/Praat",
                           script_code,
                           args = NULL,
                           iterations = 50,
                           warmup = 3) {
  
  # Warmup runs (not measured)
  if (warmup > 0) {
    for (i in seq_len(warmup)) {
      run_praat_script(praat_exe, script_code, args, measure_only_execution = TRUE)
    }
  }
  
  # Measured runs
  times <- numeric(iterations)
  for (i in seq_len(iterations)) {
    result <- run_praat_script(praat_exe, script_code, args, measure_only_execution = TRUE)
    times[i] <- result$execution_time
  }
  
  # Return statistics
  list(
    iterations = iterations,
    min = min(times),
    median = median(times),
    mean = mean(times),
    max = max(times),
    sd = sd(times),
    times = times
  )
}

#' Generate Praat script for pitch extraction
#' @param audio_file Path to audio file
#' @param time_step Time step (0 = auto)
#' @param pitch_floor Minimum pitch (Hz)
#' @param pitch_ceiling Maximum pitch (Hz)
#' @return Praat script code
praat_pitch_script <- function(audio_file, time_step = 0.0, 
                               pitch_floor = 75, pitch_ceiling = 600) {
  sprintf('
sound = Read from file: "%s"
pitch = To Pitch: %f, %f, %f
mean_f0 = Get mean: 0, 0, "Hertz"
appendInfoLine: "Mean F0: ", fixed$(mean_f0, 2), " Hz"
removeObject: sound, pitch
', audio_file, time_step, pitch_floor, pitch_ceiling)
}

#' Generate Praat script for formant extraction
#' @param audio_file Path to audio file
#' @param time_step Time step (0 = auto)
#' @param max_formants Maximum number of formants
#' @param max_freq Maximum frequency (Hz)
#' @param window_length Window length (s)
#' @param preemphasis Pre-emphasis from (Hz)
#' @return Praat script code
praat_formant_script <- function(audio_file, time_step = 0.0,
                                 max_formants = 5, max_freq = 5500,
                                 window_length = 0.025, preemphasis = 50) {
  sprintf('
sound = Read from file: "%s"
formant = To Formant (burg): %f, %d, %f, %f, %f
f1 = Get mean: 1, 0, 0, "Hertz"
f2 = Get mean: 2, 0, 0, "Hertz"
appendInfoLine: "F1: ", fixed$(f1, 2), " Hz, F2: ", fixed$(f2, 2), " Hz"
removeObject: sound, formant
', audio_file, time_step, max_formants, max_freq, window_length, preemphasis)
}

#' Generate Praat script for intensity
#' @param audio_file Path to audio file
#' @param min_pitch Minimum pitch for analysis
#' @param time_step Time step (0 = auto)
#' @return Praat script code
praat_intensity_script <- function(audio_file, min_pitch = 100, time_step = 0.0) {
  sprintf('
sound = Read from file: "%s"
intensity = To Intensity: %f, %f, "yes"
mean_int = Get mean: 0, 0, "dB"
appendInfoLine: "Mean intensity: ", fixed$(mean_int, 2), " dB"
removeObject: sound, intensity
', audio_file, min_pitch, time_step)
}

#' Generate Praat script for spectrogram
#' @param audio_file Path to audio file
#' @param window_length Window length (s)
#' @param max_freq Maximum frequency (Hz)
#' @param time_step Time step (s)
#' @param freq_step Frequency step (Hz)
#' @param window_shape Window shape
#' @return Praat script code
praat_spectrogram_script <- function(audio_file, window_length = 0.005,
                                     max_freq = 5000, time_step = 0.002,
                                     freq_step = 20, window_shape = "Gaussian") {
  sprintf('
sound = Read from file: "%s"
spectrogram = To Spectrogram: %f, %f, %f, %f, "%s"
appendInfoLine: "Spectrogram created"
removeObject: sound, spectrogram
', audio_file, window_length, max_freq, time_step, freq_step, window_shape)
}

#' Generate Praat script for harmonicity
#' @param audio_file Path to audio file
#' @param time_step Time step (0 = auto)
#' @param min_pitch Minimum pitch (Hz)
#' @param silence_threshold Silence threshold
#' @param periods_per_window Periods per window
#' @return Praat script code
praat_harmonicity_script <- function(audio_file, time_step = 0.01,
                                     min_pitch = 75, silence_threshold = 0.1,
                                     periods_per_window = 1.0) {
  sprintf('
sound = Read from file: "%s"
harmonicity = To Harmonicity (cc): %f, %f, %f, %f
mean_hnr = Get mean: 0, 0
appendInfoLine: "Mean HNR: ", fixed$(mean_hnr, 2), " dB"
removeObject: sound, harmonicity
', audio_file, time_step, min_pitch, silence_threshold, periods_per_window)
}
