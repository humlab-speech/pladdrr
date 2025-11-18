# Benchmark 5: Converted Praat Scripts Comparison
# Tests: Full workflow comparisons for converted superassp scripts
# Expected speedup: 1.5-3x overall (accounting for R overhead)

library(speaker)
library(bench)
library(reticulate)

cat("================================================================================\n")
cat("Benchmark 5: Converted Scripts Comparison\n")
cat("================================================================================\n\n")

# Check if parselmouth is available
cat("Checking for parselmouth installation...\n")
parselmouth_available <- FALSE

tryCatch({
  pm <- import("parselmouth")
  parselmouth_available <- TRUE
  cat("✓ Parselmouth version:", pm$`__version__`, "\n\n")
}, error = function(e) {
  cat("✗ Parselmouth not installed\n")
  cat("  To install: pip install praat-parselmouth\n")
  cat("  Skipping parselmouth comparison benchmarks.\n\n")
  cat("Note: This benchmark compares speaker performance against Python's\n")
  cat("      parselmouth library. Install parselmouth to run the comparison.\n\n")
})

if (!parselmouth_available) {
  cat("================================================================================\n")
  cat("BENCHMARK SKIPPED - Parselmouth not available\n")
  cat("================================================================================\n")
  cat("\nTo enable this benchmark:\n")
  cat("  1. Install Python parselmouth: pip install praat-parselmouth\n")
  cat("  2. Verify installation: python -c 'import parselmouth'\n")
  cat("  3. Re-run this benchmark\n\n")
  cat("Running speaker-only benchmarks instead...\n\n")
  
  # Run speaker-only benchmarks as fallback
  test_file <- system.file("extdata", "test.wav", package = "speaker")
  if (file.exists(test_file)) {
    cat("Speaker Performance (without comparison):\n")
    cat("────────────────────────────────────────\n")
    
    # Load sound file
    sound_file <- test_file
    
    # Basic operations benchmark - create fresh sound each time
    result <- bench::mark(
      pitch = {
        sound <- Sound$new(sound_file)
        sound$to_pitch()
      },
      formants = {
        sound <- Sound$new(sound_file)
        sound$to_formant_burg()
      },
      intensity = {
        sound <- Sound$new(sound_file)
        sound$to_intensity()
      },
      iterations = 10,
      check = FALSE
    )
    
    print(result[, c("expression", "min", "median", "itr/sec")])
    cat("\nNote: These are speaker-only timings. Install parselmouth for comparisons.\n")
  }
  
  quit(save = "no", status = 0)
}

cat("Running parselmouth comparison benchmarks...\n\n")

# Load test audio - handle missing gracefully
test_file <- system.file("extdata", "test.wav", package = "speaker")
if (!file.exists(test_file) || test_file == "") {
  cat("✗ Test audio file not found\n")
  cat("  Expected location: inst/extdata/test.wav\n")
  cat("  Using synthetic audio for speaker-only benchmarks...\n\n")
  
  cat("Speaker Performance (synthetic 440Hz tone):\n")
  cat("────────────────────────────────────────\n")
  
  # Use system.time() instead of bench::mark() for R6 objects
  cat("  Benchmarking pitch extraction...\n")
  system.time({
    for (i in 1:10) {
      sound <- Sound$create_tone(1.0, 440, 44100, 0.5)
      pitch <- sound$to_pitch()
    }
  }) -> time_pitch
  
  cat("  Benchmarking formants...\n")
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
  cat("      Install real audio file to enable full comparisons.\n\n")
  
  quit(save = "no", status = 0)
}

cat("Running benchmarks (this may take several minutes)...\n\n")

# ============================================================================
# Workflow 1: Basic voice quality analysis (jitter, shimmer, HNR)
# ============================================================================

cat("1. Voice quality analysis (jitter, shimmer, HNR)...\n")

# Parselmouth version
voice_quality_pm <- function(file) {
  snd <- pm$Sound(file)
  
  # Pitch for jitter/shimmer
  pitch <- snd$to_pitch()
  point_process <- pm$call(list(snd, pitch), "To PointProcess (cc)")
  
  # Jitter
  jitter_local <- pm$call(point_process, "Get jitter (local)", 0, 0, 0.0001, 0.02, 1.3)
  jitter_rap <- pm$call(point_process, "Get jitter (rap)", 0, 0, 0.0001, 0.02, 1.3)
  
  # Shimmer
  shimmer_local <- pm$call(list(snd, point_process), "Get shimmer (local)", 0, 0, 0.0001, 0.02, 1.3, 1.6)
  shimmer_apq3 <- pm$call(list(snd, point_process), "Get shimmer (apq3)", 0, 0, 0.0001, 0.02, 1.3, 1.6)
  
  # HNR
  harmonicity <- snd$to_harmonicity_cc()
  hnr <- pm$call(harmonicity, "Get mean", 0, 0)
  
  list(jitter_local = jitter_local, jitter_rap = jitter_rap,
       shimmer_local = shimmer_local, shimmer_apq3 = shimmer_apq3,
       hnr = hnr)
}

# Speaker version
voice_quality_speaker <- function(file) {
  snd <- Sound$new(file)
  
  # Pitch for jitter/shimmer
  pitch <- snd$to_pitch()
  point_process <- snd$to_point_process_cc(pitch)
  
  # Jitter
  jitter_local <- point_process$get_jitter_local(0, 0, 0.0001, 0.02, 1.3)
  jitter_rap <- point_process$get_jitter_rap(0, 0, 0.0001, 0.02, 1.3)
  
  # Shimmer
  shimmer_local <- point_process$get_shimmer_local(snd, 0, 0, 0.0001, 0.02, 1.3, 1.6)
  shimmer_apq3 <- point_process$get_shimmer_apq3(snd, 0, 0, 0.0001, 0.02, 1.3, 1.6)
  
  # HNR
  harmonicity <- snd$to_harmonicity()
  hnr <- harmonicity$get_mean(0, 0)
  
  list(jitter_local = jitter_local, jitter_rap = jitter_rap,
       shimmer_local = shimmer_local, shimmer_apq3 = shimmer_apq3,
       hnr = hnr)
}

voice_quality_bench <- mark(
  parselmouth = voice_quality_pm(test_file),
  speaker = voice_quality_speaker(test_file),
  iterations = 30,
  check = FALSE
)

speedup_vq <- median(voice_quality_bench$time[voice_quality_bench$expression == "parselmouth"]) / 
              median(voice_quality_bench$time[voice_quality_bench$expression == "speaker"])

cat("   Parselmouth:", format(median(voice_quality_bench$time[voice_quality_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(voice_quality_bench$time[voice_quality_bench$expression == "speaker"])), "\n")
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_vq))

# ============================================================================
# Workflow 2: Formant tracking with statistics
# ============================================================================

cat("2. Formant tracking with statistics...\n")

# Parselmouth version
formant_analysis_pm <- function(file) {
  snd <- pm$Sound(file)
  formant <- snd$to_formant_burg()
  
  # Get formant statistics
  f1_mean <- pm$call(formant, "Get mean", 1, 0, 0, "Hertz")
  f2_mean <- pm$call(formant, "Get mean", 2, 0, 0, "Hertz")
  f1_sd <- pm$call(formant, "Get standard deviation", 1, 0, 0, "Hertz")
  f2_sd <- pm$call(formant, "Get standard deviation", 2, 0, 0, "Hertz")
  
  list(f1_mean = f1_mean, f2_mean = f2_mean, f1_sd = f1_sd, f2_sd = f2_sd)
}

# Speaker version
formant_analysis_speaker <- function(file) {
  snd <- Sound$new(file)
  formant <- snd$to_formant()
  
  # Get formant statistics
  f1_mean <- formant$get_mean(1, 0, 0, "Hertz")
  f2_mean <- formant$get_mean(2, 0, 0, "Hertz")
  f1_sd <- formant$get_standard_deviation(1, 0, 0, "Hertz")
  f2_sd <- formant$get_standard_deviation(2, 0, 0, "Hertz")
  
  list(f1_mean = f1_mean, f2_mean = f2_mean, f1_sd = f1_sd, f2_sd = f2_sd)
}

formant_analysis_bench <- mark(
  parselmouth = formant_analysis_pm(test_file),
  speaker = formant_analysis_speaker(test_file),
  iterations = 30,
  check = FALSE
)

speedup_formant <- median(formant_analysis_bench$time[formant_analysis_bench$expression == "parselmouth"]) / 
                   median(formant_analysis_bench$time[formant_analysis_bench$expression == "speaker"])

cat("   Parselmouth:", format(median(formant_analysis_bench$time[formant_analysis_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(formant_analysis_bench$time[formant_analysis_bench$expression == "speaker"])), "\n")
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_formant))

# ============================================================================
# Workflow 3: Spectral analysis (CoG, moments)
# ============================================================================

cat("3. Spectral analysis (CoG, spectral moments)...\n")

# Parselmouth version
spectral_analysis_pm <- function(file) {
  snd <- pm$Sound(file)
  spectrum <- snd$to_spectrum()
  
  # Spectral moments
  cog <- pm$call(spectrum, "Get centre of gravity", 2.0)
  sd <- pm$call(spectrum, "Get standard deviation", 2.0)
  skewness <- pm$call(spectrum, "Get skewness", 2.0)
  kurtosis <- pm$call(spectrum, "Get kurtosis", 2.0)
  
  list(cog = cog, sd = sd, skewness = skewness, kurtosis = kurtosis)
}

# Speaker version
spectral_analysis_speaker <- function(file) {
  snd <- Sound$new(file)
  spectrum <- snd$to_spectrum()
  
  # Spectral moments
  cog <- spectrum$get_centre_of_gravity(2.0)
  sd <- spectrum$get_standard_deviation(2.0)
  skewness <- spectrum$get_skewness(2.0)
  kurtosis <- spectrum$get_kurtosis(2.0)
  
  list(cog = cog, sd = sd, skewness = skewness, kurtosis = kurtosis)
}

spectral_analysis_bench <- mark(
  parselmouth = spectral_analysis_pm(test_file),
  speaker = spectral_analysis_speaker(test_file),
  iterations = 30,
  check = FALSE
)

speedup_spectral <- median(spectral_analysis_bench$time[spectral_analysis_bench$expression == "parselmouth"]) / 
                    median(spectral_analysis_bench$time[spectral_analysis_bench$expression == "speaker"])

cat("   Parselmouth:", format(median(spectral_analysis_bench$time[spectral_analysis_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(spectral_analysis_bench$time[spectral_analysis_bench$expression == "speaker"])), "\n")
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_spectral))

# ============================================================================
# Workflow 4: PSOLA pitch manipulation
# ============================================================================

cat("4. PSOLA pitch manipulation...\n")

# Parselmouth version
psola_manipulation_pm <- function(file) {
  snd <- pm$Sound(file)
  manipulation <- pm$call(snd, "To Manipulation", 0.01, 75, 600)
  pitch_tier <- pm$call(manipulation, "Extract pitch tier")
  pm$call(pitch_tier, "Multiply frequencies", 0, 0, 1.5)
  pm$call(list(pitch_tier, manipulation), "Replace pitch tier")
  resynthesized <- pm$call(manipulation, "Get resynthesis (overlap-add)")
  invisible(resynthesized)
}

# Speaker version
psola_manipulation_speaker <- function(file) {
  snd <- Sound$new(file)
  manipulation <- snd$to_manipulation(0.01, 75, 600)
  pitch_tier <- manipulation$extract_pitch_tier()
  pitch_tier$multiply_frequencies(0, 0, 1.5)
  manipulation$replace_pitch_tier(pitch_tier)
  resynthesized <- manipulation$get_resynthesis_overlap_add()
  invisible(resynthesized)
}

psola_bench <- mark(
  parselmouth = psola_manipulation_pm(test_file),
  speaker = psola_manipulation_speaker(test_file),
  iterations = 20,
  check = FALSE
)

speedup_psola <- median(psola_bench$time[psola_bench$expression == "parselmouth"]) / 
                 median(psola_bench$time[psola_bench$expression == "speaker"])

cat("   Parselmouth:", format(median(psola_bench$time[psola_bench$expression == "parselmouth"])), "\n")
cat("   Speaker:    ", format(median(psola_bench$time[psola_bench$expression == "speaker"])), "\n")
cat("   Speedup:    ", sprintf("%.2fx\n\n", speedup_psola))

# Save results
results <- list(
  voice_quality = list(
    benchmark = voice_quality_bench,
    speedup = speedup_vq
  ),
  formant_analysis = list(
    benchmark = formant_analysis_bench,
    speedup = speedup_formant
  ),
  spectral_analysis = list(
    benchmark = spectral_analysis_bench,
    speedup = speedup_spectral
  ),
  psola_manipulation = list(
    benchmark = psola_bench,
    speedup = speedup_psola
  ),
  summary = data.frame(
    workflow = c("Voice Quality", "Formant Analysis", "Spectral Analysis", "PSOLA Manipulation"),
    speedup = c(speedup_vq, speedup_formant, speedup_spectral, speedup_psola)
  )
)

# Create results directory if it doesn't exist
dir.create("inst/benchmarks/results", recursive = TRUE, showWarnings = FALSE)

# Save results
saveRDS(results, "inst/benchmarks/results/05_converted_scripts_comparison.rds")

cat("========================================\n")
cat("Summary\n")
cat("========================================\n")
print(results$summary)
cat("\n")

cat("Results saved to: inst/benchmarks/results/05_converted_scripts_comparison.rds\n")
cat("Benchmark 5 complete!\n\n")
