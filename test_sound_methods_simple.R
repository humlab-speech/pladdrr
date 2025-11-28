library(pladdrr)

cat("Testing Sound Methods\n\n")

# Create simple sound from values
cat("Creating sound from numeric vector...\n")
values <- sin(2*pi*440*seq(0, 0.1, length.out=2205))  # 0.1s at 22050 Hz
sound <- Sound$from_values(values, 22050)
cat("✅ Sound created. Duration:", sound$get_total_duration(), "s\n\n")

# Now test the new periodic methods
cat("=== Test: to_pointprocess_periodic_cc ===\n")
tryCatch({
  # Check if method exists
  has_method <- "to_pointprocess_periodic_cc" %in% names(sound)
  cat("Method exists:", has_method, "\n")
  
  if (has_method) {
    pp <- sound$to_pointprocess_periodic_cc(75, 600)
    cat("✅ Method called successfully!\n")
    cat("Points detected:", pp$get_number_of_points(), "\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})

cat("\n=== Test: to_pointprocess_periodic_peaks ===\n")
tryCatch({
  has_method <- "to_pointprocess_periodic_peaks" %in% names(sound)
  cat("Method exists:", has_method, "\n")
  
  if (has_method) {
    pp <- sound$to_pointprocess_periodic_peaks(75, 600, TRUE, FALSE)
    cat("✅ Method called successfully!\n")
    cat("Points detected:", pp$get_number_of_points(), "\n")
  }
}, error = function(e) {
  cat("❌ ERROR:", conditionMessage(e), "\n")
})
