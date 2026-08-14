# Benchmark 4: Three-Way Comparison (pladdrr vs Parselmouth vs Praat)
# Tests: Direct comparison of pladdrr vs parselmouth vs native Praat
# for common operations. Expected speedup: pladdrr faster than both
# (direct C++ binding, no Python/startup overhead)


library(pladdrr)
library(bench)
library(reticulate)

# Load Praat runner helper
source("inst/benchmarks/praat_runner.R")

cat(strrep("=", 80), "\n", sep = "")
cat("Benchmark 4: Three-Way Comparison (pladdrr vs Parselmouth vs Praat)\n")
cat(strrep("=", 80), "\n\n", sep = "")

# Check Praat availability
praat_exe <- "/Applications/Praat.app/Contents/MacOS/Praat"
praat_available <- file.exists(praat_exe)
if (praat_available) {
  cat("✓ Praat found at:", praat_exe, "\n")
} else {
  cat("✗ Praat not found at:", praat_exe, "\n")
  cat("  Praat benchmarks will be skipped\n")
}
cat("\n")

# Configure Python environment
# Try conda/miniconda first, then system python
python_paths <- c(
  "/opt/miniconda3/bin/python3",
  "/opt/anaconda3/bin/python3",
  "/usr/local/bin/python3",
  "/usr/bin/python3"
)

python_found <- FALSE
for (py_path in python_paths) {
  if (file.exists(py_path)) {
    tryCatch(
      {
        use_python(py_path, required = TRUE)
        python_found <- TRUE
        cat("✓ Using Python:", py_path, "\n")
        break
      },
      error = function(e) {}
    )
  }
}

if (!python_found) {
  cat("✗ Could not find Python - using reticulate default\n")
}

# Check parselmouth availability
cat("Checking parselmouth...\n")
parselmouth_available <- FALSE

tryCatch(
  {
    pm <- import("parselmouth")
    parselmouth_available <- TRUE
    cat("✓ Parselmouth version:", pm$`__version__`, "\n\n")
  },
  error = function(e) {
    cat("✗ Parselmouth not installed - skipping comparison\n")
    cat("  Error:", conditionMessage(e), "\n")
    cat("  Install: pip install praat-parselmouth\n")
    cat("  Note: Install in the Python environment shown above\n\n")
    quit(save = "no", status = 0)
  }
)

# Load test audio file - handle missing gracefully
test_file <- system.file("extdata", "test.wav", package = "pladdrr")
if (!file.exists(test_file) || test_file == "") {
  cat("✗ Test audio file not found at inst/extdata/test.wav\n")
  cat("  Using synthetic audio for pladdrr-only benchmarks...\n\n")

  cat("Running pladdrr benchmarks (synthetic audio):\n\n")

  # Note: bench::mark() with R6 objects requires separate calls
  # due to environment/serialization issues

  cat("  Benchmarking pitch extraction...\n")
  system.time({
    for (i in 1:10) {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      pitch <- sound$to_pitch()
    }
  }) -> time_pitch

  cat("  Benchmarking formant extraction...\n")
  system.time({
    for (i in 1:10) {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      formants <- sound$to_formant_burg()
    }
  }) -> time_formants

  cat("  Benchmarking intensity...\n")
  system.time({
    for (i in 1:10) {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      intensity <- sound$to_intensity()
    }
  }) -> time_intensity

  cat("\nResults (10 iterations each):\n")
  cat(sprintf(
    "  Pitch:     %.3f seconds (%.1f ms/iter)\n",
    time_pitch["elapsed"], time_pitch["elapsed"] * 100
  ))
  cat(sprintf(
    "  Formants:  %.3f seconds (%.1f ms/iter)\n",
    time_formants["elapsed"], time_formants["elapsed"] * 100
  ))
  cat(sprintf(
    "  Intensity: %.3f seconds (%.1f ms/iter)\n",
    time_intensity["elapsed"], time_intensity["elapsed"] * 100
  ))

  cat("\nNote: Parselmouth comparison requires test.wav file\n")
  cat("      Showing pladdrr-only results instead.\n\n")

  quit(save = "no", status = 0)
}

# Helper function to run parselmouth operation
run_pm <- function(file, operation) {
  snd <- pm$Sound(file)
  switch(operation,
    "pitch" = snd$to_pitch(),
    "formant" = snd$to_formant_burg(),
    "intensity" = snd$to_intensity(),
    "spectrogram" = snd$to_spectrogram(),
    "harmonicity" = snd$to_harmonicity_cc(),
    stop("Unknown operation")
  )
}

# Helper function to run pladdrr operation
run_pladdrr <- function(file, operation) {
  snd <- Sound$new(file)
  switch(operation,
    "pitch" = snd$to_pitch(),
    "formant" = snd$to_formant_burg(),
    "intensity" = snd$to_intensity(),
    "spectrogram" = snd$to_spectrogram(),
    "harmonicity" = snd$to_harmonicity_cc(),
    stop("Unknown operation")
  )
}

cat("Running benchmarks (this may take several minutes)...\n\n")

# 1. Pitch extraction
cat("1. Pitch extraction (autocorrelation)...\n")

# Run pladdrr benchmark
pladdrr_bench <- mark(
  pladdrr = run_pladdrr(test_file, "pitch"),
  iterations = 50,
  check = FALSE
)
sp_time <- pladdrr_bench$median[1]
cat("   pladdrr:    ", format(sp_time), "\n")

# Run parselmouth benchmark
pm_bench <- mark(
  parselmouth = run_pm(test_file, "pitch"),
  iterations = 50,
  check = FALSE
)
pm_time <- pm_bench$median[1]
cat("   Parselmouth:", format(pm_time), "\n")

# Run Praat benchmark (if available)
praat_time <- NULL
if (praat_available) {
  cat("   Running Praat benchmark...\n")
  praat_script <- praat_pitch_script(test_file,
    time_step = 0.0,
    pitch_floor = 75, pitch_ceiling = 600
  )
  praat_result <- benchmark_praat(
    praat_exe, praat_script,
    iterations = 50, warmup = 3
  )
  praat_time <- praat_result$median
  cat("   Praat:      ", sprintf("%.4f s", praat_time), "\n")
}

# Calculate speedups
speedup_vs_pm <- as.numeric(pm_time) / as.numeric(sp_time)
cat("   vs Parselmouth: ", sprintf("%.2fx", speedup_vs_pm))
if (speedup_vs_pm >= 1) {
  cat(" (pladdrr faster)\n")
} else {
  cat(" (Parselmouth faster)\n")
}

if (!is.null(praat_time)) {
  speedup_vs_praat <- praat_time / as.numeric(sp_time)
  cat("   vs Praat:       ", sprintf("%.2fx", speedup_vs_praat))
  if (speedup_vs_praat >= 1) {
    cat(" (pladdrr faster)\n")
  } else {
    cat(" (Praat faster)\n")
  }
}
cat("\n")

# 2. Formant tracking
cat("2. Formant tracking (Burg method)...\n")

pladdrr_bench <- mark(
  pladdrr = run_pladdrr(test_file, "formant"),
  iterations = 50,
  check = FALSE
)
sp_time <- pladdrr_bench$median[1]
cat("   pladdrr:    ", format(sp_time), "\n")

pm_bench <- mark(
  parselmouth = run_pm(test_file, "formant"),
  iterations = 50,
  check = FALSE
)
pm_time <- pm_bench$median[1]
cat("   Parselmouth:", format(pm_time), "\n")

praat_time_formant <- NULL
if (praat_available) {
  cat("   Running Praat benchmark...\n")
  praat_script <- praat_formant_script(test_file,
    time_step = 0.0, max_formants = 5,
    max_freq = 5500, window_length = 0.025, preemphasis = 50
  )
  praat_result <- benchmark_praat(
    praat_exe, praat_script,
    iterations = 50, warmup = 3
  )
  praat_time_formant <- praat_result$median
  cat("   Praat:      ", sprintf("%.4f s", praat_time_formant), "\n")
}

speedup_formant <- as.numeric(pm_time) / as.numeric(sp_time)
cat("   vs Parselmouth: ", sprintf("%.2fx", speedup_formant))
if (speedup_formant >= 1) {
  cat(" (pladdrr faster)\n")
} else {
  cat(" (Parselmouth faster)\n")
}

if (!is.null(praat_time_formant)) {
  speedup_vs_praat_formant <- praat_time_formant / as.numeric(sp_time)
  cat("   vs Praat:       ", sprintf("%.2fx", speedup_vs_praat_formant))
  if (speedup_vs_praat_formant >= 1) {
    cat(" (pladdrr faster)\n")
  } else {
    cat(" (Praat faster)\n")
  }
}
cat("\n")

# 3. Intensity calculation
cat("3. Intensity calculation...\n")

pladdrr_bench <- mark(
  pladdrr = run_pladdrr(test_file, "intensity"),
  iterations = 50,
  check = FALSE
)
sp_time <- pladdrr_bench$median[1]
cat("   pladdrr:    ", format(sp_time), "\n")

pm_bench <- mark(
  parselmouth = run_pm(test_file, "intensity"),
  iterations = 50,
  check = FALSE
)
pm_time <- pm_bench$median[1]
cat("   Parselmouth:", format(pm_time), "\n")

praat_time_intensity <- NULL
if (praat_available) {
  cat("   Running Praat benchmark...\n")
  praat_script <- praat_intensity_script(
    test_file, min_pitch = 100, time_step = 0.0
  )
  praat_result <- benchmark_praat(
    praat_exe, praat_script,
    iterations = 50, warmup = 3
  )
  praat_time_intensity <- praat_result$median
  cat("   Praat:      ", sprintf("%.4f s", praat_time_intensity), "\n")
}

speedup_intensity <- as.numeric(pm_time) / as.numeric(sp_time)
cat("   vs Parselmouth: ", sprintf("%.2fx", speedup_intensity))
if (speedup_intensity >= 1) {
  cat(" (pladdrr faster)\n")
} else {
  cat(" (Parselmouth faster)\n")
}

if (!is.null(praat_time_intensity)) {
  speedup_vs_praat_intensity <- praat_time_intensity / as.numeric(sp_time)
  cat("   vs Praat:       ", sprintf("%.2fx", speedup_vs_praat_intensity))
  if (speedup_vs_praat_intensity >= 1) {
    cat(" (pladdrr faster)
")
  } else {
    cat(" (Praat faster)
")
  }
}
cat("\n")

# 4. Spectrogram generation
cat("4. Spectrogram generation...\n")

pladdrr_bench <- mark(
  pladdrr = run_pladdrr(test_file, "spectrogram"),
  iterations = 50,
  check = FALSE
)
sp_time <- pladdrr_bench$median[1]
cat("   pladdrr:    ", format(sp_time), "\n")

pm_bench <- mark(
  parselmouth = run_pm(test_file, "spectrogram"),
  iterations = 50,
  check = FALSE
)
pm_time <- pm_bench$median[1]
cat("   Parselmouth:", format(pm_time), "\n")

praat_time_spectrogram <- NULL
if (praat_available) {
  cat("   Running Praat benchmark...\n")
  praat_script <- praat_spectrogram_script(test_file,
    window_length = 0.005,
    max_freq = 5000, time_step = 0.002,
    freq_step = 20, window_shape = "Gaussian"
  )
  praat_result <- benchmark_praat(
    praat_exe, praat_script,
    iterations = 50, warmup = 3
  )
  praat_time_spectrogram <- praat_result$median
  cat("   Praat:      ", sprintf("%.4f s", praat_time_spectrogram), "\n")
}

speedup_spectrogram <- as.numeric(pm_time) / as.numeric(sp_time)
cat("   vs Parselmouth: ", sprintf("%.2fx", speedup_spectrogram))
if (speedup_spectrogram >= 1) {
  cat(" (pladdrr faster)
")
} else {
  cat(" (Parselmouth faster)
")
}

if (!is.null(praat_time_spectrogram)) {
  speedup_vs_praat_spectrogram <- praat_time_spectrogram / as.numeric(sp_time)
  cat("   vs Praat:       ", sprintf("%.2fx", speedup_vs_praat_spectrogram))
  if (speedup_vs_praat_spectrogram >= 1) {
    cat(" (pladdrr faster)
")
  } else {
    cat(" (Praat faster)
")
  }
}
cat("\n")

# 5. Harmonicity (HNR)
cat("5. Harmonicity (HNR)...\n")

pladdrr_bench <- mark(
  pladdrr = run_pladdrr(test_file, "harmonicity"),
  iterations = 50,
  check = FALSE
)
sp_time <- pladdrr_bench$median[1]
cat("   pladdrr:    ", format(sp_time), "\n")

pm_bench <- mark(
  parselmouth = run_pm(test_file, "harmonicity"),
  iterations = 50,
  check = FALSE
)
pm_time <- pm_bench$median[1]
cat("   Parselmouth:", format(pm_time), "\n")

praat_time_harmonicity <- NULL
if (praat_available) {
  cat("   Running Praat benchmark...\n")
  praat_script <- praat_harmonicity_script(test_file,
    time_step = 0.01,
    min_pitch = 75, silence_threshold = 0.1,
    periods_per_window = 1.0
  )
  praat_result <- benchmark_praat(
    praat_exe, praat_script,
    iterations = 50, warmup = 3
  )
  praat_time_harmonicity <- praat_result$median
  cat("   Praat:      ", sprintf("%.4f s", praat_time_harmonicity), "\n")
}

speedup_harmonicity <- as.numeric(pm_time) / as.numeric(sp_time)
cat("   vs Parselmouth: ", sprintf("%.2fx", speedup_harmonicity))
if (speedup_harmonicity >= 1) {
  cat(" (pladdrr faster)
")
} else {
  cat(" (Parselmouth faster)
")
}

if (!is.null(praat_time_harmonicity)) {
  speedup_vs_praat_harmonicity <- praat_time_harmonicity / as.numeric(sp_time)
  cat("   vs Praat:       ", sprintf("%.2fx", speedup_vs_praat_harmonicity))
  if (speedup_vs_praat_harmonicity >= 1) {
    cat(" (pladdrr faster)
")
  } else {
    cat(" (Praat faster)
")
  }
}
cat("\n")

# Save results
results <- list(
  pitch = list(
    pladdrr_time = as.numeric(sp_time),
    parselmouth_time = as.numeric(pm_time),
    praat_time = praat_time,
    speedup_vs_parselmouth = speedup_vs_pm,
    speedup_vs_praat = if (!is.null(praat_time)) {
      praat_time / as.numeric(sp_time)
    } else {
      NA
    }
  ),
  formant = list(
    pladdrr_time = as.numeric(sp_time),
    parselmouth_time = as.numeric(pm_time),
    praat_time = praat_time_formant,
    speedup_vs_parselmouth = speedup_formant,
    speedup_vs_praat = if (!is.null(praat_time_formant)) {
      praat_time_formant / as.numeric(sp_time)
    } else {
      NA
    }
  ),
  intensity = list(
    pladdrr_time = as.numeric(sp_time),
    parselmouth_time = as.numeric(pm_time),
    praat_time = praat_time_intensity,
    speedup_vs_parselmouth = speedup_intensity,
    speedup_vs_praat = if (!is.null(praat_time_intensity)) {
      praat_time_intensity / as.numeric(sp_time)
    } else {
      NA
    }
  ),
  spectrogram = list(
    pladdrr_time = as.numeric(sp_time),
    parselmouth_time = as.numeric(pm_time),
    praat_time = praat_time_spectrogram,
    speedup_vs_parselmouth = speedup_spectrogram,
    speedup_vs_praat = if (!is.null(praat_time_spectrogram)) {
      praat_time_spectrogram / as.numeric(sp_time)
    } else {
      NA
    }
  ),
  harmonicity = list(
    pladdrr_time = as.numeric(sp_time),
    parselmouth_time = as.numeric(pm_time),
    praat_time = praat_time_harmonicity,
    speedup_vs_parselmouth = speedup_harmonicity,
    speedup_vs_praat = if (!is.null(praat_time_harmonicity)) {
      praat_time_harmonicity / as.numeric(sp_time)
    } else {
      NA
    }
  ),
  summary = data.frame(
    operation = c(
      "Pitch", "Formant", "Intensity", "Spectrogram", "Harmonicity"
    ),
    speedup = c(
      speedup_vs_pm, speedup_formant, speedup_intensity,
      speedup_spectrogram, speedup_harmonicity
    ),
    speedup_vs_parselmouth = c(
      speedup_vs_pm, speedup_formant, speedup_intensity,
      speedup_spectrogram, speedup_harmonicity
    ),
    speedup_vs_praat = c(
      if (!is.null(praat_time)) {
        praat_time / as.numeric(sp_time)
      } else {
        NA
      },
      if (!is.null(praat_time_formant)) {
        praat_time_formant / as.numeric(sp_time)
      } else {
        NA
      },
      if (!is.null(praat_time_intensity)) {
        praat_time_intensity / as.numeric(sp_time)
      } else {
        NA
      },
      if (!is.null(praat_time_spectrogram)) {
        praat_time_spectrogram / as.numeric(sp_time)
      } else {
        NA
      },
      if (!is.null(praat_time_harmonicity)) {
        praat_time_harmonicity / as.numeric(sp_time)
      } else {
        NA
      }
    )
  )
)

# Create results directory if it doesn't exist
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)

# Save results
saveRDS(results, "inst/benchmarks/results/04_parselmouth_comparison.rds")

cat("========================================\n")
cat("Summary\n")
cat("========================================\n")
print(results$summary)
cat("\n")

cat("Results saved to: inst/benchmarks/results/04_parselmouth_comparison.rds\n")
cat("Benchmark 4 complete!\n\n")
