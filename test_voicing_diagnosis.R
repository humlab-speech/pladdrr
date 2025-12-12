library(pladdrr)

# Load audio
snd <- Sound$new("inst/signalfiles/AVQI/input/sv1.wav")

# Extract pitch
pitch <- snd$to_pitch_cc(
  time_step = 0.015,
  pitch_floor = 60,
  pitch_ceiling = 350,
  max_candidates = 15,
  silence_threshold = 0.03,
  voicing_threshold = 0.3,
  octave_cost = 0.01,
  octave_jump_cost = 0.35,
  voiced_unvoiced_cost = 0.14
) 2>&1 | grep -E "(GLOBAL_PEAK|Frame (4|5|6|7|8|9) |intensity=)" | head -20

cat("\n=== DIAGNOSIS ===\n")
cat("Extract debug output above to see:\n")
cat("1. globalPeak value\n")
cat("2. localPeak and intensity for frames 4-9\n")
cat("3. Compare these to Praat's expected behavior\n")
