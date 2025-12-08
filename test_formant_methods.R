library(pladdrr)

snd <- Sound$new('inst/extdata/test.wav')

cat("\n=== Testing Burg method (working) ===\n")
f_burg <- snd$to_formant_burg()
cat("Burg: ", f_burg$get_number_of_frames(), " frames\n")

cat("\n=== Testing KeepAll method ===\n")
tryCatch({
  f_keepall <- snd$to_formant_keepall()
  cat("KeepAll: ", f_keepall$get_number_of_frames(), " frames\n")
}, error = function(e) {
  cat("KeepAll FAILED:", conditionMessage(e), "\n")
})

cat("\n=== Testing SL method ===\n")
tryCatch({
  f_sl <- snd$to_formant_sl()
  cat("SL: ", f_sl$get_number_of_frames(), " frames\n")
}, error = function(e) {
  cat("SL FAILED:", conditionMessage(e), "\n")
})

cat("\n=== Willems method (known to crash) - SKIPPED ===\n")
# f_willems <- snd$to_formant_willems()  # CRASHES

cat("\nDone!\n")
