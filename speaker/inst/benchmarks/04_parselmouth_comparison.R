# Benchmark 4: Parselmouth Comparison
# Tests: Direct comparison of speaker vs parselmouth for common operations
# Expected speedup: 1.5-3x (direct C++ binding vs Python overhead)


library(speaker)
library(bench)
library(reticulate)

cat("================================================================================\n")
cat("Benchmark 4: Parselmouth Comparison\n")
cat("================================================================================\n\n")

# Check parselmouth availability
cat("Checking parselmouth...\n")
parselmouth_available <- FALSE

tryCatch({
  pm <- import("parselmouth")
  parselmouth_available <- TRUE
  cat("✓ Parselmouth version:", pm$`__version__`, "\n\n")
}, error = function(e) {
  cat("✗ Parselmouth not installed - skipping comparison\n")
  cat("  Install: pip install praat-parselmouth\n\n")
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
  snd <- Sound$new(file, use_av = TRUE)
  switch(operation,
    "pitch" = snd$to_pitch(),
    "formant" = snd$to_formant(),
    "intensity" = snd$to_intensity(),
    "spectrogram" = snd$to_spectrogram(),
    "harmonicity" = snd$to_harmonicity(),
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

cat("   Parselmouth:", format(median(pitch_bench$time[pitch_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(pitch_bench$time[pitch_bench$expression == "speaker"])), "\n")
speedup_pitch <- median(pitch_bench$time[pitch_bench$expression == "parselmouth"]) / 
                 median(pitch_bench$time[pitch_bench$expression == "speaker"])
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_pitch))

# 2. Formant tracking
cat("2. Formant tracking (Burg method)...\n")
formant_bench <- mark(
  parselmouth = run_pm(test_file, "formant"),
  speaker = run_speaker(test_file, "formant"),
  iterations = 50,
  check = FALSE
)

cat("   Parselmouth:", format(median(formant_bench$time[formant_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(formant_bench$time[formant_bench$expression == "speaker"])), "\n")
speedup_formant <- median(formant_bench$time[formant_bench$expression == "parselmouth"]) / 
                   median(formant_bench$time[formant_bench$expression == "speaker"])
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_formant))

# 3. Intensity calculation
cat("3. Intensity calculation...\n")
intensity_bench <- mark(
  parselmouth = run_pm(test_file, "intensity"),
  speaker = run_speaker(test_file, "intensity"),
  iterations = 50,
  check = FALSE
)

cat("   Parselmouth:", format(median(intensity_bench$time[intensity_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(intensity_bench$time[intensity_bench$expression == "speaker"])), "\n")
speedup_intensity <- median(intensity_bench$time[intensity_bench$expression == "parselmouth"]) / 
                     median(intensity_bench$time[intensity_bench$expression == "speaker"])
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_intensity))

# 4. Spectrogram generation
cat("4. Spectrogram generation...\n")
spectrogram_bench <- mark(
  parselmouth = run_pm(test_file, "spectrogram"),
  speaker = run_speaker(test_file, "spectrogram"),
  iterations = 50,
  check = FALSE
)

cat("   Parselmouth:", format(median(spectrogram_bench$time[spectrogram_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(spectrogram_bench$time[spectrogram_bench$expression == "speaker"])), "\n")
speedup_spectrogram <- median(spectrogram_bench$time[spectrogram_bench$expression == "parselmouth"]) / 
                       median(spectrogram_bench$time[spectrogram_bench$expression == "speaker"])
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_spectrogram))

# 5. Harmonicity (HNR)
cat("5. Harmonicity (HNR)...\n")
harmonicity_bench <- mark(
  parselmouth = run_pm(test_file, "harmonicity"),
  speaker = run_speaker(test_file, "harmonicity"),
  iterations = 50,
  check = FALSE
)

cat("   Parselmouth:", format(median(harmonicity_bench$time[harmonicity_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(harmonicity_bench$time[harmonicity_bench$expression == "speaker"])), "\n")
speedup_harmonicity <- median(harmonicity_bench$time[harmonicity_bench$expression == "parselmouth"]) / 
                       median(harmonicity_bench$time[harmonicity_bench$expression == "speaker"])
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_harmonicity))

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
