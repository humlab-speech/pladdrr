# Test PointProcess peaks functionality
library(pladdrr)

# Create test sound
sound <- Sound$create_tone(duration = 0.5, sampling_rate = 22050, frequency = 440)

# Test canonical method (with underscore)
cat("Testing to_point_process_periodic_peaks()...\n")
pp1 <- sound$to_point_process_periodic_peaks(
  pitch_floor = 75,
  pitch_ceiling = 600,
  include_maxima = TRUE,
  include_minima = FALSE
)
print(pp1)
cat("Number of points:", pp1$get_number_of_points(), "\n\n")

# Test alias (without underscore) - backward compatibility
cat("Testing to_pointprocess_periodic_peaks() [alias]...\n")
pp2 <- sound$to_pointprocess_periodic_peaks(
  pitch_floor = 75,
  pitch_ceiling = 600,
  include_maxima = TRUE,
  include_minima = FALSE
)
print(pp2)
cat("Number of points:", pp2$get_number_of_points(), "\n\n")

# Test periodic_cc canonical method
cat("Testing to_point_process_periodic_cc()...\n")
pp3 <- sound$to_point_process_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)
print(pp3)
cat("Number of points:", pp3$get_number_of_points(), "\n\n")

# Test periodic_cc alias
cat("Testing to_pointprocess_periodic_cc() [alias]...\n")
pp4 <- sound$to_pointprocess_periodic_cc(
  pitch_floor = 75,
  pitch_ceiling = 600
)
print(pp4)
cat("Number of points:", pp4$get_number_of_points(), "\n\n")

cat("✅ All tests passed!\n")
