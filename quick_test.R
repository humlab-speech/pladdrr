# Quick test using pkgload (compiles on-demand)
suppressMessages(library(pkgload))
cat("Loading package with pkgload...\n")

# This will compile only what's needed
load_all(".", export_all = FALSE, helpers = FALSE, attach_testthat = FALSE)

cat("\n=== Quick LTAS Unit Test ===\n")
tryCatch({
  # Test basic functionality
  snd <- Sound$new("inst/extdata/test.wav")
  cat("Sound loaded: duration =", snd$get_duration(), "s\n")
  
  ltas <- snd$to_ltas(100)
  cat("LTAS created\n")
  
  # Critical test: energy unit
  slope <- ltas$get_slope(1000, 2000, 1000, 4000, unit = "energy")
  cat("LTAS slope (energy):", slope, "\n")
  cat("Is finite:", is.finite(slope), "\n")
  
  if (is.finite(slope)) {
    cat("\n✓ SUCCESS: LTAS energy unit works!\n")
  } else {
    cat("\n✗ FAILED: LTAS energy unit returns invalid value\n")
  }
}, error = function(e) {
  cat("\n✗ ERROR:", conditionMessage(e), "\n")
})
