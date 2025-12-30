# Test Formant Module Conversion

library(pladdrr)

cat("========================================\n")
cat("Formant Module Test\n")
cat("========================================\n\n")

# 1. Create test sound
cat("1. Creating test sound...\n")
t <- seq(0, 1, length.out = 44100)
values <- sin(2 * pi * 440 * t)
sound <- create_sound(values, sampling_rate = 44100)

# 2. Extract formants
cat("2. Extracting formants...\n")
formant <- sound$to_formant_burg(
  time_step = 0.01,
  max_formants = 5.0,
  max_frequency = 5500.0,
  window_length = 0.025,
  pre_emphasis_from = 50.0
)

# 3. Test properties
cat("\n3. Testing properties...\n")
cat(sprintf("   Frames: %d\n", formant$get_number_of_frames()))
cat(sprintf("   Time step: %.6f s\n", formant$get_time_step()))
cat(sprintf("   Min formants: %d\n", formant$get_min_num_formants()))
cat(sprintf("   Max formants: %d\n", formant$get_max_num_formants()))

# 4. Test query methods
cat("\n4. Testing query methods...\n")
f1_at_0.5 <- formant$get_value_at_time(1, 0.5, "hertz")
f2_at_0.5 <- formant$get_value_at_time(2, 0.5, "hertz")
cat(sprintf("   F1 at 0.5s: %.2f Hz\n", f1_at_0.5))
cat(sprintf("   F2 at 0.5s: %.2f Hz\n", f2_at_0.5))

mean_f1 <- formant$get_mean(1, 0, 0, "hertz")
mean_f2 <- formant$get_mean(2, 0, 0, "hertz")
cat(sprintf("   Mean F1: %.2f Hz\n", mean_f1))
cat(sprintf("   Mean F2: %.2f Hz\n", mean_f2))

# 5. Test export
cat("\n5. Testing export methods...\n")
df <- formant$as_data_frame(max_formants = 3)
cat(sprintf("   DataFrame: %d rows, %d cols\n", nrow(df), ncol(df)))

# 6. Test print
cat("\n6. Testing print method...\n")
print(formant)

cat("\n========================================\n")
cat("✓ All Formant module tests passed\n")
cat("========================================\n")
