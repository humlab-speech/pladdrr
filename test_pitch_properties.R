# Test which pitch methods work and which segfault
library(pladdrr)

cat("=== CREATING SOUND & PITCH ===\n")
sound <- Sound$create_tone(duration = 0.2, frequency = 200, sampling_rate = 16000, amplitude = 0.9)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

cat("\n=== BASIC PROPERTIES (should work) ===\n")
tryCatch({
  cat("Frames:", pitch$get_number_of_frames(), "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

tryCatch({
  cat("Time step:", pitch$get_time_step(), "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

tryCatch({
  cat("Floor:", pitch$get_pitch_floor(), "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

cat("\n=== FRAME DATA ACCESS (may segfault if frames corrupted) ===\n")

cat("Trying get_value_at_time...\n")
tryCatch({
  val <- pitch$get_value_at_time(0.05)
  cat("Value at 0.05s:", val, "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

cat("\nTrying get_mean...\n")
tryCatch({
  mean_f0 <- pitch$get_mean()
  cat("Mean F0:", mean_f0, "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

cat("\nTrying as_data_frame (accesses ALL frames)...\n")
tryCatch({
  df <- pitch$as_data_frame()
  cat("Data frame rows:", nrow(df), "\n")
  cat("SUCCESS\n")
}, error = function(e) cat("FAILED:", e$message, "\n"))

cat("\n=== DONE ===\n")
