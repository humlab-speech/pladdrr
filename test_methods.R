library(pladdrr)

# Test both methods
snd <- Sound$new('inst/extdata/test.wav')

# Test to_pitch (should work)
cat("Testing to_pitch...\n")
tryCatch({
  pitch <- snd$to_pitch()
  cat("SUCCESS: to_pitch works!\n\n")
}, error = function(e) {
  cat("ERROR in to_pitch:", conditionMessage(e), "\n\n")
})

# Test to_powercepstrogram
cat("Testing to_powercepstrogram...\n")
tryCatch({
  pcep <- snd$to_powercepstrogram()
  cat("SUCCESS: to_powercepstrogram works!\n\n")
}, error = function(e) {
  cat("ERROR in to_powercepstrogram:", conditionMessage(e), "\n\n")
  cat("Traceback:\n")
  print(traceback())
})
