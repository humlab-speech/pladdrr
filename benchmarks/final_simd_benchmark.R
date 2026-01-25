# final_simd_benchmark.R
# Task 4.5: Final comprehensive SIMD benchmark suite
# Tests all SIMD-optimized operations across Phases 1-4

library(pladdrr)

cat("============================================================\n")
cat("pladdrr SIMD Final Benchmark Suite\n")
cat("============================================================\n")
cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
cat("Package version:", as.character(packageVersion("pladdrr")), "\n")
cat("Platform:", R.version$platform, "\n")
cat("R version:", R.version.string, "\n\n")

# Check SIMD availability
simd_info <- tryCatch(pladdrr:::.get_simd_info(), error = function(e) list(
  simd_available = FALSE,
  architecture = "unknown"
))
cat("SIMD available:", simd_info$simd_available, "\n")
cat("Architecture:", simd_info$architecture, "\n")
cat("============================================================\n\n")

# Benchmark helper
benchmark_op <- function(name, scalar_fn, simd_fn, iterations = 20) {
  # Warmup
  for (i in 1:3) { try(scalar_fn(), silent = TRUE); try(simd_fn(), silent = TRUE) }

  # Scalar timing
  options(speaker.use_simd = FALSE)
  scalar_times <- numeric(iterations)
  for (i in 1:iterations) {
    scalar_times[i] <- system.time(scalar_fn())[["elapsed"]]
  }

  # SIMD timing
  options(speaker.use_simd = TRUE)
  simd_times <- numeric(iterations)
  for (i in 1:iterations) {
    simd_times[i] <- system.time(simd_fn())[["elapsed"]]
  }

  scalar_median <- median(scalar_times) * 1000  # ms
  simd_median <- median(simd_times) * 1000      # ms
  speedup <- scalar_median / simd_median

  list(
    name = name,
    scalar_ms = scalar_median,
    simd_ms = simd_median,
    speedup = speedup
  )
}

results <- list()

# Create test audio using correct API
cat("Creating test audio signals...\n")
set.seed(42)
samples_1s <- 0.5 * sin(2 * pi * 440 * seq(0, 1, length.out = 44100))
samples_5s <- 0.5 * sin(2 * pi * 440 * seq(0, 5, length.out = 220500))
sound_1s <- Sound$from_values(samples_1s, 44100)
sound_5s <- Sound$from_values(samples_5s, 44100)

cat("Test signals: 1s and 5s at 44100 Hz\n")
cat(sprintf("1s signal: %d samples, %.2fs duration\n", sound_1s$get_number_of_samples(), sound_1s$get_duration()))
cat(sprintf("5s signal: %d samples, %.2fs duration\n", sound_5s$get_number_of_samples(), sound_5s$get_duration()))
cat("\n")

# ============================================================
# Phase 1: Core Operations
# ============================================================
cat("=== PHASE 1: Core Operations ===\n")

# Pitch extraction (AC method)
cat("Testing pitch extraction (AC)...\n")
tryCatch({
  res <- benchmark_op("Pitch (AC, 5s)",
    function() { options(speaker.use_simd = FALSE); sound_5s$to_pitch() },
    function() { options(speaker.use_simd = TRUE); sound_5s$to_pitch() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# Formant extraction
cat("Testing formant extraction...\n")
tryCatch({
  res <- benchmark_op("Formant (Burg, 5s)",
    function() { options(speaker.use_simd = FALSE); sound_5s$to_formant_burg() },
    function() { options(speaker.use_simd = TRUE); sound_5s$to_formant_burg() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# Intensity
cat("Testing intensity calculation...\n")
tryCatch({
  res <- benchmark_op("Intensity (5s)",
    function() { options(speaker.use_simd = FALSE); sound_5s$to_intensity() },
    function() { options(speaker.use_simd = TRUE); sound_5s$to_intensity() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# ============================================================
# Phase 2: Spectrogram & Filtering
# ============================================================
cat("\n=== PHASE 2: Spectrogram & Filtering ===\n")

# Spectrogram
cat("Testing spectrogram generation...\n")
tryCatch({
  res <- benchmark_op("Spectrogram (5s)",
    function() { options(speaker.use_simd = FALSE); sound_5s$to_spectrogram() },
    function() { options(speaker.use_simd = TRUE); sound_5s$to_spectrogram() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# Pre-emphasis
cat("Testing pre-emphasis filter...\n")
tryCatch({
  # Pre-emphasis is applied in-place, need fresh copies
  res <- benchmark_op("Pre-emphasis (5s)",
    function() {
      options(speaker.use_simd = FALSE)
      s <- Sound(sound_5s$as_matrix()[1,], 44100)
      s$pre_emphasize(50)
    },
    function() {
      options(speaker.use_simd = TRUE)
      s <- Sound(sound_5s$as_matrix()[1,], 44100)
      s$pre_emphasize(50)
    }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# ============================================================
# Phase 3: Batch Operations
# ============================================================
cat("\n=== PHASE 3: Batch Operations ===\n")

# TextGrid batch duration calculation
cat("Testing TextGrid batch operations...\n")
tryCatch({
  # Create test arrays for SIMD batch operations
  n <- 10000
  starts <- runif(n, 0, 10)
  ends <- starts + runif(n, 0.1, 0.5)

  res <- benchmark_op("TextGrid durations (10k intervals)",
    function() {
      options(speaker.use_simd = FALSE)
      pladdrr:::.calculate_durations_simd_bridge(starts, ends)
    },
    function() {
      options(speaker.use_simd = TRUE)
      pladdrr:::.calculate_durations_simd_bridge(starts, ends)
    }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# ============================================================
# Phase 4: Advanced Features
# ============================================================
cat("\n=== PHASE 4: Advanced Features ===\n")

# Harmonicity
cat("Testing harmonicity calculation...\n")
tryCatch({
  res <- benchmark_op("Harmonicity (CC, 1s)",
    function() { options(speaker.use_simd = FALSE); sound_1s$to_harmonicity_cc() },
    function() { options(speaker.use_simd = TRUE); sound_1s$to_harmonicity_cc() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# FormantPath
cat("Testing FormantPath...\n")
tryCatch({
  res <- benchmark_op("FormantPath (1s, 5 ceilings)",
    function() {
      options(speaker.use_simd = FALSE)
      sound_1s$to_formant_path(ceiling_step = 500, number_of_steps_per_ceiling_step = 5)
    },
    function() {
      options(speaker.use_simd = TRUE)
      sound_1s$to_formant_path(ceiling_step = 500, number_of_steps_per_ceiling_step = 5)
    }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# ComplexSpectrogram
cat("Testing ComplexSpectrogram...\n")
tryCatch({
  res <- benchmark_op("ComplexSpectrogram (1s)",
    function() { options(speaker.use_simd = FALSE); sound_1s$to_complex_spectrogram() },
    function() { options(speaker.use_simd = TRUE); sound_1s$to_complex_spectrogram() }
  )
  results[[length(results) + 1]] <- res
  cat(sprintf("  Scalar: %.2f ms, SIMD: %.2f ms, Speedup: %.2fx\n",
              res$scalar_ms, res$simd_ms, res$speedup))
}, error = function(e) cat("  ERROR:", e$message, "\n"))

# ============================================================
# Summary
# ============================================================
cat("\n============================================================\n")
cat("FINAL BENCHMARK SUMMARY\n")
cat("============================================================\n")

if (length(results) > 0) {
  df <- do.call(rbind, lapply(results, as.data.frame))

  cat(sprintf("%-40s %10s %10s %10s\n", "Operation", "Scalar(ms)", "SIMD(ms)", "Speedup"))
  cat(rep("-", 72), "\n", sep = "")

  for (i in 1:nrow(df)) {
    cat(sprintf("%-40s %10.2f %10.2f %10.2fx\n",
                df$name[i], df$scalar_ms[i], df$simd_ms[i], df$speedup[i]))
  }

  cat(rep("-", 72), "\n", sep = "")
  geom_mean <- exp(mean(log(df$speedup)))
  cat(sprintf("%-40s %10s %10s %10.2fx\n", "GEOMETRIC MEAN SPEEDUP", "", "", geom_mean))

  cat("\n")
  cat("Platform notes:\n")
  cat("- ARM NEON (batch size 2): Typical speedup 1.0-1.2x\n")
  cat("- x86 AVX2 (batch size 4): Expected speedup 1.5-3.0x\n")
  cat("============================================================\n")
}

options(speaker.use_simd = TRUE)  # Reset to default
cat("Benchmark complete.\n")
