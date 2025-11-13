# Benchmark 5: Converted Praat Scripts Comparison
# Tests: Full workflow comparisons for converted superassp scripts
# Expected speedup: 1.5-3x overall (accounting for R overhead)

library(speaker)
library(bench)
library(reticulate)

cat("========================================\n")
cat("Benchmark 5: Converted Scripts Comparison\n")
cat("========================================\n\n")

# Initialize Python
cat("Initializing Python environment...\n")
pm <- import("parselmouth")
cat("Parselmouth version:", pm$`__version__`, "\n\n")

# Load test audio
test_file <- system.file("extdata", "test.wav", package = "speaker")
if (!file.exists(test_file)) {
  stop("Test audio file not found.")
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
