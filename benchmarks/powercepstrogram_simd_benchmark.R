# PowerCepstrogram SIMD Benchmark (v4.8.10)
# Measures SIMD speedup for CPPS calculation (primary AVQI bottleneck)

library(pladdrr)

cat("PowerCepstrogram SIMD Benchmark\n")
cat("================================\n\n")

# Check SIMD availability
simd_available <- tryCatch({
  .Call("_pladdrr_should_use_simd_for_powercepstrogram_bridge", PACKAGE = "pladdrr")
}, error = function(e) FALSE)

cat("SIMD Available:", simd_available, "\n")
cat("Platform:", R.version$platform, "\n")
cat("Architecture:", Sys.info()["machine"], "\n\n")

# Test configurations
configs <- list(
  list(duration = 1.0, freq = 440, name = "1s_tone"),
  list(duration = 5.0, freq = 500, name = "5s_tone"),
  list(duration = 10.0, freq = 600, name = "10s_tone")
)

results <- list()

for (cfg in configs) {
  cat(sprintf("Testing: %s (%.1fs, %d Hz)\n", cfg$name, cfg$duration, cfg$freq))
  
  # Create test sound
  sound <- generate_sine_wave(cfg$freq, duration = cfg$duration, sampling_rate = 16000)
  
  # Benchmark PowerCepstrogram creation (internally uses SIMD)
  times <- system.time(replicate(10, {
    sound$to_powercepstrogram(
      pitch_floor = 60,
      time_step = 0.002,
      max_frequency = 5000,
      pre_emphasis_from = 50
    )
  }))
  
  avg_time_ms <- (times["elapsed"] / 10) * 1000
  
  cat(sprintf("  Average time: %.2f ms\n", avg_time_ms))
  
  # Benchmark CPPS (uses PowerCepstrogram)
  cpps_times <- system.time(replicate(10, {
    calculate_cpps_ultra(sound)
  }))
  
  cpps_avg_ms <- (cpps_times["elapsed"] / 10) * 1000
  
  cat(sprintf("  CPPS time: %.2f ms\n", cpps_avg_ms))
  
  results[[cfg$name]] <- list(
    duration = cfg$duration,
    powercepstrogram_ms = avg_time_ms,
    cpps_ms = cpps_avg_ms
  )
  
  cat("\n")
}

cat("Summary\n")
cat("-------\n")
for (name in names(results)) {
  r <- results[[name]]
  cat(sprintf("%s: PowerCepstrogram=%.2fms, CPPS=%.2fms\n", 
              name, r$powercepstrogram_ms, r$cpps_ms))
}

cat("\nExpected improvements (v4.8.10):\n")
cat("- ARM NEON: 1.15-1.20x speedup\n")
cat("- x86 AVX2: 1.25-1.35x speedup\n")
cat("- AVQI R/Python ratio: 1.58x -> ~1.38x (13% improvement)\n")
