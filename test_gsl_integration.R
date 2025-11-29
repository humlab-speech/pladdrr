library(pladdrr)

cat("=== Testing GSL Integration ===\n\n")

# Test 1: Basic Sound operations that rely on statistical functions
cat("Test 1: Sound creation and LPC analysis (uses GSL poly solvers)\n")
sound <- Sound$new(system.file("extdata", "test.wav", package = "pladdrr"))
cat("✓ Sound loaded successfully\n")

# Test 2: LPC analysis (uses gsl_poly_solve_quadratic via NUMmath.cpp)
cat("\nTest 2: LPC analysis (requires GSL polynomial solvers)\n")
tryCatch({
  lpc <- sound$to_lpc_burg(prediction_order = 16, window_length = 0.025, time_step = 0.005, 
                           pre_emphasis_frequency = 50)
  cat("✓ LPC analysis successful\n")
  cat("  LPC frames:", lpc$get_number_of_frames(), "\n")
}, error = function(e) {
  cat("✗ LPC failed:", conditionMessage(e), "\n")
})

# Test 3: PowerCepstrum (uses statistical functions via NUMspecfunc.cpp)
cat("\nTest 3: PowerCepstrum (uses GSL special functions)\n")
tryCatch({
  pc <- sound$to_powercepstrum(pitch_floor = 60, time_step = 0.002)
  cat("✓ PowerCepstrum analysis successful\n")
  peak_prom <- pc$get_peak_prominence(60, 333.3, "parabolic", 0.001, 0.05, "straight", "robust")
  cat("  Peak prominence:", peak_prom, "\n")
}, error = function(e) {
  cat("✗ PowerCepstrum failed:", conditionMessage(e), "\n")
})

cat("\n=== GSL Integration Test Complete ===\n")
