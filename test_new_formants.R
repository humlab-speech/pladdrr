library(pladdrr)

# Create test sound
sound <- Sound$create_tone(duration = 0.5, frequency = 440)

# Test new formant methods
cat("Testing Willems method...\n")
formants_willems <- sound$to_formant_willems(number_of_formants = 3)
cat("Willems: OK - ", formants_willems$get_number_of_frames(), " frames\n")

cat("Testing Split-Levinson method...\n")
formants_sl <- sound$to_formant_sl(number_of_poles = 6)
cat("Split-Levinson: OK - ", formants_sl$get_number_of_frames(), " frames\n")

cat("Comparing with Burg method...\n")
formants_burg <- sound$to_formant_burg()
cat("Burg: OK - ", formants_burg$get_number_of_frames(), " frames\n")

cat("\nAll formant extraction methods working successfully!\n")
