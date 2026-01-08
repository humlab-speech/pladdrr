# Test script for fast CPPS performance API
# Run: Rscript dev/test_cpps_fast.R

library(pladdrr)

cat("=== Testing Fast CPPS API ===\n\n")

# Load test sound
sound_file <- system.file("signalfiles", "sound.wav", package = "pladdrr")
if (!file.exists(sound_file)) {
  cat("ERROR: Test sound file not found\n")
  quit(status = 1)
}

sound <- Sound(sound_file)
cat("Loaded test sound:", sound_file, "\n")
cat("Duration:", sound$get_total_duration(), "s\n\n")

# Test 1: Standard API
cat("Test 1: Standard API (R6 methods)\n")
time_standard <- system.time({
  pcep <- sound$to_powercepstrogram(60, 0.002, 5000, 50)
  cpps_standard <- pcep$get_cpps(
    subtract_tilt = FALSE,
    time_averaging_window = 0.01,
    quefrency_averaging_window = 0.001,
    pitch_floor = 60,
    pitch_ceiling = 330,
    delta_f0 = 0.05,
    interpolation = "parabolic",
    quefrency_range_start = 0.001,
    quefrency_range_end = 0,
    trend_line_type = "straight",
    fit_method = "robust"
  )
})
cat("  CPPS:", cpps_standard, "dB\n")
cat("  Time:", time_standard["elapsed"], "s\n\n")

# Test 2: Fast API (all-in-one)
cat("Test 2: Fast API - calculate_cpps_fast()\n")
time_fast <- system.time({
  cpps_fast <- calculate_cpps_fast(
    sound,
    subtract_tilt = FALSE,
    time_averaging_window = 0.01,
    quefrency_averaging_window = 0.001,
    pitch_floor = 60,
    pitch_ceiling = 330,
    delta_f0 = 0.05,
    interpolation = "parabolic",
    qstart_fit = 0.001,
    qend_fit = 0,
    trend_line_type = "straight",
    fit_method = "robust"
  )
})
cat("  CPPS:", cpps_fast, "dB\n")
cat("  Time:", time_fast["elapsed"], "s\n\n")

# Test 3: Fast API (two-step)
cat("Test 3: Fast API - to_powercepstrogram_fast() + get_cpps_fast()\n")
time_fast2 <- system.time({
  pcep_ptr <- to_powercepstrogram_fast(sound, 60, 0.002, 5000, 50)
  cpps_fast2 <- get_cpps_fast(
    pcep_ptr,
    subtract_tilt = FALSE,
    time_averaging_window = 0.01,
    quefrency_averaging_window = 0.001,
    pitch_floor = 60,
    pitch_ceiling = 330,
    delta_f0 = 0.05,
    interpolation = "parabolic",
    qstart_fit = 0.001,
    qend_fit = 0,
    trend_line_type = "straight",
    fit_method = "robust"
  )
})
cat("  CPPS:", cpps_fast2, "dB\n")
cat("  Time:", time_fast2["elapsed"], "s\n\n")

# Verify results match
cat("=== Results Comparison ===\n")
cat("Standard API:    ", cpps_standard, "dB\n")
cat("Fast API (v1):   ", cpps_fast, "dB\n")
cat("Fast API (v2):   ", cpps_fast2, "dB\n")
cat("Match tolerance: ", all.equal(cpps_standard, cpps_fast, tolerance = 1e-10), "\n")
cat("Match (v1 vs v2):", all.equal(cpps_fast, cpps_fast2, tolerance = 1e-10), "\n\n")

# Performance comparison
cat("=== Performance Comparison ===\n")
speedup1 <- time_standard["elapsed"] / time_fast["elapsed"]
speedup2 <- time_standard["elapsed"] / time_fast2["elapsed"]
cat("Standard time:   ", time_standard["elapsed"], "s\n")
cat("Fast (v1) time:  ", time_fast["elapsed"], "s  (", sprintf("%.2fx", speedup1), "speedup)\n")
cat("Fast (v2) time:  ", time_fast2["elapsed"], "s  (", sprintf("%.2fx", speedup2), "speedup)\n\n")

if (speedup1 >= 1.3) {
  cat("✓ SUCCESS: Fast API achieves >= 1.3x speedup\n")
} else {
  cat("✗ WARNING: Fast API speedup (", sprintf("%.2fx", speedup1), ") is less than expected (1.5-2x)\n")
}

cat("\n=== Test Complete ===\n")
