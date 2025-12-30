# Test Spectrum Module Conversion

library(pladdrr)

cat("========================================\n")
cat("Spectrum Module Test\n")
cat("========================================\n\n")

# 1. Create test sound
cat("1. Creating test sound (440 Hz)...\n")
t <- seq(0, 1, length.out = 44100)
values <- sin(2 * pi * 440 * t)
sound <- create_sound(values, sampling_rate = 44100)

# 2. Extract spectrum
cat("2. Extracting spectrum...\n")
spectrum <- sound$to_spectrum(fast = TRUE)

# 3. Test properties
cat("\n3. Testing properties...\n")
cat(sprintf("   Freq range: %.2f - %.2f Hz\n", 
            spectrum$get_lowest_frequency(),
            spectrum$get_highest_frequency()))
cat(sprintf("   Bins: %d\n", spectrum$get_number_of_bins()))
cat(sprintf("   Freq step: %.2f Hz\n", spectrum$get_frequency_step()))

# 4. Test query methods
cat("\n4. Testing query methods...\n")
cog <- spectrum$get_centre_of_gravity(power = 2.0)
sd <- spectrum$get_standard_deviation(power = 2.0)
skew <- spectrum$get_skewness(power = 2.0)
kurt <- spectrum$get_kurtosis(power = 2.0)
cat(sprintf("   CoG: %.2f Hz\n", cog))
cat(sprintf("   SD: %.2f Hz\n", sd))
cat(sprintf("   Skewness: %.2f\n", skew))
cat(sprintf("   Kurtosis: %.2f\n", kurt))

# 5. Test band energy
cat("\n5. Testing band energy...\n")
energy_100_1000 <- spectrum$get_band_energy(100, 1000)
cat(sprintf("   Energy 100-1000Hz: %.2e\n", energy_100_1000))

# 6. Test bin access
cat("\n6. Testing bin access...\n")
bin10_real <- spectrum$get_real_value_in_bin(10)
bin10_imag <- spectrum$get_imaginary_value_in_bin(10)
cat(sprintf("   Bin 10: real=%.2e, imag=%.2e\n", bin10_real, bin10_imag))

# 7. Test export
cat("\n7. Testing export methods...\n")
mat <- spectrum$as_matrix()
cat(sprintf("   Matrix: %dx%d\n", nrow(mat), ncol(mat)))
df <- spectrum$as_data_frame()
cat(sprintf("   DataFrame: %d rows, %d cols\n", nrow(df), ncol(df)))

# 8. Test print
cat("\n8. Testing print method...\n")
print(spectrum)

cat("\n========================================\n")
cat("✓ All Spectrum module tests passed\n")
cat("========================================\n")
