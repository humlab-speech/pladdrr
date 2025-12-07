# Analysis script to understand pitch detection parameters

cat("=== Praat Default Parameters ===\n")
cat("From Sound_to_Pitch.cpp line 495:\n")
cat("maxnCandidates = 15\n")
cat("veryAccurate = false\n")
cat("silenceThreshold = 0.03\n")
cat("voicingThreshold = 0.45\n")
cat("octaveCost = 0.01\n")
cat("octaveJumpCost = 0.35\n")
cat("voicedUnvoicedCost = 0.14\n\n")

cat("=== Critical Code Path ===\n")
cat("Sound_to_Pitch() calls Sound_to_Pitch_rawAc() with defaults\n")
cat("Sound_to_Pitch_rawAc() calls Sound_to_Pitch_any()\n")
cat("Sound_to_Pitch_any() loops over frames calling Sound_into_PitchFrame()\n\n")

cat("=== Key Logic in Sound_into_PitchFrame (line 177-178) ===\n")
cat("if (localPeak == 0.0) return;  // Shortcut for silence\n\n")

cat("=== Candidate Detection (line 186) ===\n")
cat("if (r[i] > 0.5 * voicingThreshold && r[i] > r[i-1] && r[i] >= r[i+1])\n")
cat("   => r[i] > 0.5 * 0.45 = 0.225\n")
cat("   => Autocorrelation must exceed 0.225 at a lag peak\n\n")

cat("=== Hypothesis ===\n")
cat("Issue is likely in one of:\n")
cat("1. localPeak calculation (line 90-101) - returns 0 for valid signal?\n")
cat("2. Autocorrelation r[] values - all below 0.225 threshold?\n")
cat("3. Window function killing signal?\n")
cat("4. DC removal subtracting too much?\n\n")

cat("To diagnose, we need to add printf/Melder_casual at:\n")
cat("- Line 102: pitchFrame->intensity value\n")
cat("- Line 177: localPeak value before silence check\n")
cat("- Line 186: r[i] values in candidate search loop\n")
