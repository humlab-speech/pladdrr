library(pladdrr)

# Create simple 200 Hz tone
tone <- Sound$create_tone(duration = 1.0, frequency = 200, amplitude = 0.9, sampling_rate = 16000)

# Extract pitch
pitch <- tone$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

# Check results
cat("Pitch object created\n")
cat("Number of frames:", pitch$get_number_of_frames(), "\n")
cat("Time step:", pitch$get_time_step(), "\n")

# Count voiced frames
df <- pitch$as_data_frame()
cat("\nDataFrame dimensions:", nrow(df), "x", ncol(df), "\n")
cat("Columns:", paste(names(df), collapse=", "), "\n")
cat("First 10 rows:\n")
print(head(df, 10))

voiced <- sum(!is.na(df$frequency) & df$frequency > 0, na.rm=TRUE)
cat("\nVoiced frames:", voiced, "/", nrow(df), "\n")

if (voiced > 0) {
  cat("Mean F0:", mean(df$frequency, na.rm=TRUE), "Hz\n")
  cat("SUCCESS: Pitch detection working!\n")
} else {
  cat("FAIL: Still zero voiced frames\n")
}
