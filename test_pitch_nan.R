# Check if pitch values are NaN vs NA
library(pladdrr)

sound <- Sound$create_tone(duration = 0.2, frequency = 200, sampling_rate = 16000, amplitude = 0.9)
pitch <- sound$to_pitch(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600)

df <- pitch$as_data_frame()

cat("Data frame:\n")
print(df)

cat("\n=== VALUE TYPES ===\n")
cat("NA count:", sum(is.na(df$frequency)), "\n")
cat("NaN count:", sum(is.nan(df$frequency)), "\n")
cat("Finite count:", sum(is.finite(df$frequency)), "\n")

cat("\n=== DIRECT VALUE TESTS ===\n")
val <- pitch$get_value_at_time(0.1)
cat("Value at 0.1s:", val, "\n")
cat("  is.na:", is.na(val), "\n")
cat("  is.nan:", is.nan(val), "\n")
cat("  is.finite:", is.finite(val), "\n")

cat("\n=== COMPARISON ===\n")
cat("Expected for 200 Hz sine: all frames ~200 Hz\n")
cat("Actual: all NaN\n")
cat("\nThis means Praat's pitch detection is RUNNING but returning NaN,\n")
cat("not failing to run. The algorithm executes but can't find pitch.\n")
