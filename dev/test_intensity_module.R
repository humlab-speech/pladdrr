# Test Intensity Module Conversion

library(pladdrr)

cat("========================================\n")
cat("Intensity Module Test\n")
cat("========================================\n\n")

# 1. Create test sound
cat("1. Creating test sound (440 Hz)...\n")
t <- seq(0, 1, length.out = 44100)
values <- sin(2 * pi * 440 * t)
sound <- create_sound(values, sampling_rate = 44100)

# 2. Extract intensity
cat("2. Extracting intensity...\n")
intensity <- sound$to_intensity(minimum_pitch = 50, time_step = 0.01)

# 3. Test properties
cat("\n3. Testing properties...\n")
cat(sprintf("   Duration: %.3f s\n", intensity$get_end_time() - intensity$get_start_time()))
cat(sprintf("   Frames: %d\n", intensity$get_number_of_frames()))
cat(sprintf("   Time step: %.4f s\n", intensity$get_sampling_period()))

# 4. Test query methods
cat("\n4. Testing query methods...\n")
cat(sprintf("   Mean: %.2f dB\n", intensity$get_mean()))
cat(sprintf("   Min: %.2f dB\n", intensity$get_minimum()))
cat(sprintf("   Max: %.2f dB\n", intensity$get_maximum()))
cat(sprintf("   SD: %.2f dB\n", intensity$get_standard_deviation()))
cat(sprintf("   Median: %.2f dB\n", intensity$get_quantile(quantile = 0.5)))

# 5. Test time methods
cat("\n5. Testing time methods...\n")
t_min <- intensity$get_time_of_minimum()
t_max <- intensity$get_time_of_maximum()
cat(sprintf("   Time of min: %.3f s\n", t_min))
cat(sprintf("   Time of max: %.3f s\n", t_max))

# 6. Test value access
cat("\n6. Testing value access...\n")
val_at_0.5 <- intensity$get_value_at_time(0.5)
cat(sprintf("   Value at 0.5s: %.2f dB\n", val_at_0.5))

# 7. Test export
cat("\n7. Testing export methods...\n")
df <- intensity$as_data_frame()
cat(sprintf("   DataFrame: %d rows, cols: %s\n", nrow(df), paste(names(df), collapse = ", ")))
mat <- intensity$as_matrix()
cat(sprintf("   Matrix: %dx%d\n", nrow(mat), ncol(mat)))

# 8. Test print
cat("\n8. Testing print method...\n")
print(intensity)

cat("\n========================================\n")
cat("✓ All Intensity module tests passed\n")
cat("========================================\n")
