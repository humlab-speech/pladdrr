#!/usr/bin/env Rscript
# CPPS (Cepstral Peak Prominence Smoothed) Analysis Example
# 
# This example demonstrates correct usage of PowerCepstrogram and CPPS
#  calculation
# in pladdrr. CPPS is a robust measure of voice quality, particularly useful for
# assessing dysphonia and voice disorders.
#
# Key Learning Points:
# 1. Correct parameter names for to_powercepstrogram()
# 2. Understanding CPPS parameters and their effects
# 3. Comparing different analysis settings
# 4. Interpreting CPPS values for voice quality

library(pladdrr)

# Load test sound (should be voiced speech, ideally 3+ seconds)
# For this example, we'll use the package test file
sound_file <- system.file("extdata", "test.wav", package = "pladdrr")

if (!file.exists(sound_file)) {
  stop("Test file not found. Please use your own audio file.")
}

cat("==============================================\n")
cat("CPPS Analysis Example\n")
cat("==============================================\n\n")

# Load sound
sound <- Sound$new(sound_file)
cat(sprintf("Loaded: %s\n", basename(sound_file)))
cat(sprintf("Duration: %.3f seconds\n", sound$get_duration()))
cat(sprintf("Sample rate: %d Hz\n", sound$get_sampling_frequency()))
cat(sprintf("Channels: %d\n\n", sound$get_number_of_channels()))

# ============================================================================
# IMPORTANT: Correct Parameter Names
# ============================================================================
#
# Common mistakes (WRONG):
#   - max_frequency        →  Should be: maximum_frequency
#   - pre_emphasis_from    →  Should be: pre_emphasis_frequency
#
# These incorrect names will be silently ignored and defaults used instead!
# ============================================================================

cat("Step 1: Creating PowerCepstrogram\n")
cat("----------------------------------\n")
cat("Parameters:\n")
cat("  pitch_floor: 60 Hz (typical for male voices)\n")
cat("  time_step: 0.002 s (2 ms, standard for voice analysis)\n")
cat("  maximum_frequency: 5000 Hz (Nyquist consideration)\n")
cat("  pre_emphasis_frequency: 50 Hz (enhance higher frequencies)\n\n")

# Create PowerCepstrogram with CORRECT parameter names
cepstrogram <- sound$to_powercepstrogram(
  pitch_floor = 60,                    # ✓ Correct
  time_step = 0.002,                   # ✓ Correct
  maximum_frequency = 5000,            # ✓ NOTE: maximum_frequency (full word!)
  pre_emphasis_frequency = 50          # ✓ NOTE: pre_emphasis_frequency (not pre_emphasis_from!)
)

cat("✓ PowerCepstrogram created successfully\n\n")

# ============================================================================
# Analysis 1: CPPS without tilt subtraction (raw cepstral peak)
# ============================================================================

cat("Step 2: Calculate CPPS (No Tilt Subtraction)\n")
cat("---------------------------------------------\n")
cat("This gives the raw cepstral peak prominence, suitable for:\n")
cat("  - Direct comparison with Praat output\n")
cat("  - Research requiring unmodified CPPS values\n")
cat("  - AVQI calculations (v2.03 and v3.01)\n\n")

cpps_no_tilt <- cepstrogram$get_cpps(
  subtract_tilt = FALSE,               # Do not remove trend line
  time_averaging_window = 0.01,        # 10 ms smoothing window
  quefrency_averaging_window = 0.001,  # 1 ms quefrency smoothing
  pitch_floor = 60,                    # Search range start
  pitch_ceiling = 330,                 # Search range end (typical for speech)
  delta_f0 = 0.05,                     # Tolerance for peak detection (5%)
  interpolation = "parabolic",         # Sub-sample peak interpolation
  quefrency_range_start = 0.001,       # Start of fit range (1 ms)
  quefrency_range_end = 0,             # End of fit range (0 = auto: 1/pitch_floor)
  trend_line_type = "straight",        # Linear trend line
  fit_method = "robust"                # Robust regression (outlier resistant)
)

cat(sprintf("CPPS (no tilt): %.2f dB\n\n", cpps_no_tilt))

# ============================================================================
# Analysis 2: CPPS with tilt subtraction (normalized)
# ============================================================================

cat("Step 3: Calculate CPPS (With Tilt Subtraction)\n")
cat("-----------------------------------------------\n")
cat("This removes the spectral tilt, useful for:\n")
cat("  - Comparing speakers with different voice qualities\n")
cat("  - Normalizing for recording conditions\n")
cat("  - Clinical voice quality assessment\n\n")

cpps_with_tilt <- cepstrogram$get_cpps(
  subtract_tilt = TRUE,                # Remove trend line before calculation
  time_averaging_window = 0.001,       # Default: 1 ms
  quefrency_averaging_window = 0.0005, # Default: 0.5 ms
  pitch_floor = 60,
  pitch_ceiling = 333.3,               # Default pitch ceiling
  delta_f0 = 0.05,
  interpolation = "parabolic",
  quefrency_range_start = 0.001,
  quefrency_range_end = 0.05,          # Default: 50 ms
  trend_line_type = "straight",
  fit_method = "robust"
)

cat(sprintf("CPPS (with tilt): %.2f dB\n\n", cpps_with_tilt))
cat(
  sprintf("Difference (tilt effect): %.2f dB\n\n",
    cpps_with_tilt - cpps_no_tilt))

# ============================================================================
# Analysis 3: Effect of pitch range
# ============================================================================

cat("Step 4: CPPS Sensitivity to Pitch Range\n")
cat("----------------------------------------\n")

# Narrower range (typical female voice)
cpps_female <- cepstrogram$get_cpps(
  subtract_tilt = FALSE,
  pitch_floor = 100,
  pitch_ceiling = 500,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001
)

# Wider range (to capture all harmonics)
cpps_wide <- cepstrogram$get_cpps(
  subtract_tilt = FALSE,
  pitch_floor = 50,
  pitch_ceiling = 600,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001
)

cat(sprintf("CPPS (male range, 60-330 Hz):   %.2f dB\n", cpps_no_tilt))
cat(sprintf("CPPS (female range, 100-500 Hz): %.2f dB\n", cpps_female))
cat(sprintf("CPPS (wide range, 50-600 Hz):    %.2f dB\n\n", cpps_wide))

# ============================================================================
# Analysis 4: Effect of pre-emphasis
# ============================================================================

cat("Step 5: Effect of Pre-emphasis\n")
cat("-------------------------------\n")

# Without pre-emphasis
cepstrogram_no_preemph <- sound$to_powercepstrogram(
  pitch_floor = 60,
  time_step = 0.002,
  maximum_frequency = 5000,
  pre_emphasis_frequency = 0           # No pre-emphasis
)

cpps_no_preemph <- cepstrogram_no_preemph$get_cpps(
  subtract_tilt = FALSE,
  time_averaging_window = 0.01,
  quefrency_averaging_window = 0.001,
  pitch_floor = 60,
  pitch_ceiling = 330
)

cat(sprintf("CPPS with pre-emphasis (50 Hz):    %.2f dB\n", cpps_no_tilt))
cat(sprintf("CPPS without pre-emphasis (0 Hz):  %.2f dB\n", cpps_no_preemph))
cat(
  sprintf("Pre-emphasis effect:                %.2f dB\n\n",
    cpps_no_preemph - cpps_no_tilt))

# ============================================================================
# Interpretation Guide
# ============================================================================

cat("==============================================\n")
cat("CPPS Interpretation Guide\n")
cat("==============================================\n\n")

cat("Typical CPPS Values:\n")
cat("  - Normal voice:        > 10-12 dB\n")
cat("  - Mild dysphonia:      8-10 dB\n")
cat("  - Moderate dysphonia:  5-8 dB\n")
cat("  - Severe dysphonia:    < 5 dB\n\n")

cat("Your results:\n")
if (cpps_no_tilt > 12) {
  cat(sprintf("  CPPS = %.2f dB → Likely normal voice quality\n", cpps_no_tilt))
} else if (cpps_no_tilt > 10) {
  cat(
    sprintf("  CPPS = %.2f dB → Borderline/mild quality issues\n",
      cpps_no_tilt))
} else if (cpps_no_tilt > 8) {
  cat(sprintf("  CPPS = %.2f dB → Moderate quality issues\n", cpps_no_tilt))
} else {
  cat(sprintf("  CPPS = %.2f dB → Significant quality issues\n", cpps_no_tilt))
}

cat("\n")
cat("==============================================\n")
cat("Key Takeaways\n")
cat("==============================================\n\n")

cat("1. Always use correct parameter names:\n")
cat("   ✓ maximum_frequency (not max_frequency)\n")
cat("   ✓ pre_emphasis_frequency (not pre_emphasis_from)\n\n")

cat("2. Match Praat parameters exactly for comparison:\n")
cat("   - Use subtract_tilt = FALSE to match Praat \"no\" option\n")
cat("   - Default parameters differ between pladdrr and Praat!\n\n")

cat("3. CPPS is sensitive to:\n")
cat("   - Pitch range specification (±2-3 dB)\n")
cat("   - Pre-emphasis settings (±2-4 dB)\n")
cat("   - Tilt subtraction (±2 dB)\n\n")

cat("4. For clinical use:\n")
cat("   - Use consistent parameters across all recordings\n")
cat("   - Record in quiet environment (background noise affects CPPS)\n")
cat("   - Use sustained vowels for most reliable measurements\n")
cat("   - Compare to age- and gender-matched norms\n\n")

cat("✓ Example completed successfully!\n")

# ============================================================================
# Additional Resources
# ============================================================================
#
# For more information on CPPS:
# - Hillenbrand et al. (1994) - Original CPPS paper
# - Maryn et al. (2010) - CPPS for voice quality assessment
# - Barsties & De Bodt (2015) - AVQI including CPPS
#
# Praat CPPS documentation:
# https://www.fon.hum.uva.nl/praat/manual/PowerCepstrogram__Get_CPPS___.html
#
# Package documentation:
# ?PowerCepstrogram
# ?Sound
# ============================================================================
