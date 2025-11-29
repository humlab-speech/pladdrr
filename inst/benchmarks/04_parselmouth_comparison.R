# Benchmark 4: Parselmouth Comparison
# Tests: Direct comparison of speaker vs parselmouth for common operations
# Expected speedup: 1.5-3x (direct C++ binding vs Python overhead)


library(speaker)
library(bench)
library(reticulate)

cat("================================================================================\n")
cat("Benchmark 4: Parselmouth Comparison\n")
cat("================================================================================\n\n")

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
    tryCatch({
      use_python(py_path, required = TRUE)
      python_found <- TRUE
      cat("✓ Using Python:", py_path, "\n")
      break
    }, error = function(e) {})
  }
}

if (!python_found) {
  cat("✗ Could not find Python - using reticulate default\n")
}

# Check parselmouth availability
cat("Checking parselmouth...\n")
parselmouth_available <- FALSE

tryCatch({
  pm <- import("parselmouth")
  parselmouth_available <- TRUE
  cat("✓ Parselmouth version:", pm$`__version__`, "\n\n")
}, error = function(e) {
  cat("✗ Parselmouth not installed - skipping comparison\n")
  cat("  Error:", conditionMessage(e), "\n")
  cat("  Install: pip install praat-parselmouth\n")
  cat("  Note: Install in the Python environment shown above\n\n")
  quit(save = "no", status = 0)
})

# Load test audio file - handle missing gracefully
test_file <- system.file("extdata", "test.wav", package = "speaker")
if (!file.exists(test_file) || test_file == "") {
  cat("✗ Test audio file not found at inst/extdata/test.wav\n")
  cat("  Using synthetic audio for speaker-only benchmarks...\n\n")
  
  cat("Running speaker benchmarks (synthetic audio):\n\n")
  
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
  cat(sprintf("  Pitch:     %.3f seconds (%.1f ms/iter)\n", 
              time_pitch["elapsed"], time_pitch["elapsed"]*100))
  cat(sprintf("  Formants:  %.3f seconds (%.1f ms/iter)\n", 
              time_formants["elapsed"], time_formants["elapsed"]*100))
  cat(sprintf("  Intensity: %.3f seconds (%.1f ms/iter)\n", 
              time_intensity["elapsed"], time_intensity["elapsed"]*100))
  
  cat("\nNote: Parselmouth comparison requires test.wav file\n")
  cat("      Showing speaker-only results instead.\n\n")
  
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

# Helper function to run speaker operation
run_speaker <- function(file, operation) {
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
pitch_bench <- mark(
  parselmouth = run_pm(test_file, "pitch"),
  speaker = run_speaker(test_file, "pitch"),
  iterations = 50,
  check = FALSE
)

pm_time <- pitch_bench$median[1]
sp_time <- pitch_bench$median[2]
cat("   Parselmouth:", format(pm_time), "\n")
cat("   Speaker:    ", format(sp_time), "\n")
speedup_pitch <- as.numeric(sp_time) / as.numeric(pm_time)
cat("   Speedup:    ", sprintf("%.2fx", speedup_pitch))
if (speedup_pitch > 1) {
  cat(" (Parselmouth is ", sprintf("%.2fx", speedup_pitch), " faster)\n\n")
} else {
  cat(" (speaker is ", sprintf("%.2fx", 1/speedup_pitch), " faster)\n\n")
}

# 2. Formant tracking
cat("2. Formant tracking (Burg method)...\n")
formant_bench <- mark(
  parselmouth = run_pm(test_file, "formant"),
  speaker = run_speaker(test_file, "formant"),
  iterations = 50,
  check = FALSE
)

pm_time <- formant_bench$median[1]
sp_time <- formant_bench$median[2]
cat("   Parselmouth:", format(pm_time), "\n")
cat("   Speaker:    ", format(sp_time), "\n")
speedup_formant <- as.numeric(sp_time) / as.numeric(pm_time)
cat("   Speedup:    ", sprintf("%.2fx", speedup_formant))
if (speedup_formant > 1) {
  cat(" (Parselmouth is ", sprintf("%.2fx", speedup_formant), " faster)\n\n")
} else {
  cat(" (speaker is ", sprintf("%.2fx", 1/speedup_formant), " faster)\n\n")
}

# 3. Intensity calculation
cat("3. Intensity calculation...\n")
intensity_bench <- mark(
  parselmouth = run_pm(test_file, "intensity"),
  speaker = run_speaker(test_file, "intensity"),
  iterations = 50,
  check = FALSE
)

pm_time <- intensity_bench$median[1]
sp_time <- intensity_bench$median[2]
cat("   Parselmouth:", format(pm_time), "\n")
cat("   Speaker:    ", format(sp_time), "\n")
speedup_intensity <- as.numeric(sp_time) / as.numeric(pm_time)
cat("   Speedup:    ", sprintf("%.2fx", speedup_intensity))
if (speedup_intensity > 1) {
  cat(" (Parselmouth is ", sprintf("%.2fx", speedup_intensity), " faster)\n\n")
} else {
  cat(" (speaker is ", sprintf("%.2fx", 1/speedup_intensity), " faster)\n\n")
}

# 4. Spectrogram generation
cat("4. Spectrogram generation...\n")
spectrogram_bench <- mark(
  parselmouth = run_pm(test_file, "spectrogram"),
  speaker = run_speaker(test_file, "spectrogram"),
  iterations = 50,
  check = FALSE
)

pm_time <- spectrogram_bench$median[1]
sp_time <- spectrogram_bench$median[2]
cat("   Parselmouth:", format(pm_time), "\n")
cat("   Speaker:    ", format(sp_time), "\n")
speedup_spectrogram <- as.numeric(sp_time) / as.numeric(pm_time)
cat("   Speedup:    ", sprintf("%.2fx", speedup_spectrogram))
if (speedup_spectrogram > 1) {
  cat(" (Parselmouth is ", sprintf("%.2fx", speedup_spectrogram), " faster)\n\n")
} else {
  cat(" (speaker is ", sprintf("%.2fx", 1/speedup_spectrogram), " faster)\n\n")
}

# 5. Harmonicity (HNR)
cat("5. Harmonicity (HNR)...\n")
harmonicity_bench <- mark(
  parselmouth = run_pm(test_file, "harmonicity"),
  speaker = run_speaker(test_file, "harmonicity"),
  iterations = 50,
  check = FALSE
)

pm_time <- harmonicity_bench$median[1]
sp_time <- harmonicity_bench$median[2]
cat("   Parselmouth:", format(pm_time), "\n")
cat("   Speaker:    ", format(sp_time), "\n")
speedup_harmonicity <- as.numeric(sp_time) / as.numeric(pm_time)
cat("   Speedup:    ", sprintf("%.2fx", speedup_harmonicity))
if (speedup_harmonicity > 1) {
  cat(" (Parselmouth is ", sprintf("%.2fx", speedup_harmonicity), " faster)\n\n")
} else {
  cat(" (speaker is ", sprintf("%.2fx", 1/speedup_harmonicity), " faster)\n\n")
}

# Save results
results <- list(
  pitch = list(
    benchmark = pitch_bench,
    speedup = speedup_pitch
  ),
  formant = list(
    benchmark = formant_bench,
    speedup = speedup_formant
  ),
  intensity = list(
    benchmark = intensity_bench,
    speedup = speedup_intensity
  ),
  spectrogram = list(
    benchmark = spectrogram_bench,
    speedup = speedup_spectrogram
  ),
  harmonicity = list(
    benchmark = harmonicity_bench,
    speedup = speedup_harmonicity
  ),
  summary = data.frame(
    operation = c("Pitch", "Formant", "Intensity", "Spectrogram", "Harmonicity"),
    speedup = c(speedup_pitch, speedup_formant, speedup_intensity, 
                speedup_spectrogram, speedup_harmonicity)
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
