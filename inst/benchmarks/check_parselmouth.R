# Helper script to check parselmouth installation
# This can be run before benchmarks to verify Python dependencies

cat(strrep("=", 80), "\n", sep = "")
cat("Parselmouth Installation Check\n")
cat(strrep("=", 80), "\n\n", sep = "")

library(reticulate)

# Check Python availability
cat("1. Checking Python installation...\n")
py_config <- py_config()
cat("   Python executable:", py_config$python, "\n")
cat("   Python version:", paste(py_config$version, collapse = "."), "\n\n")

# Check parselmouth
cat("2. Checking for parselmouth module...\n")
parselmouth_available <- py_module_available("parselmouth")

if (parselmouth_available) {
  pm <- import("parselmouth")
  cat("   ✓ Parselmouth is installed\n")
  cat("   Version:", pm$`__version__`, "\n\n")

  cat(strrep("=", 80), "\n", sep = "")
  cat("STATUS: Ready to run parselmouth comparison benchmarks ✓\n")
  cat(strrep("=", 80), "\n\n", sep = "")
} else {
  cat("   ✗ Parselmouth is NOT installed\n\n")

  cat(strrep("=", 80), "\n", sep = "")
  cat("STATUS: Parselmouth not available\n")
  cat(strrep("=", 80), "\n\n", sep = "")

  cat("To install parselmouth:\n\n")
  cat("Option 1 - Using pip (recommended):\n")
  cat("  pip install praat-parselmouth\n\n")

  cat("Option 2 - From R:\n")
  cat("  py_install('praat-parselmouth')\n\n")

  cat("Option 3 - Using conda:\n")
  cat("  conda install -c conda-forge praat-parselmouth\n\n")

  cat("After installation, verify with:\n")
  cat("  python -c 'import parselmouth; print(parselmouth.__version__)'\n\n")

  cat("Note: Parselmouth is only needed for comparison benchmarks.\n")
  cat("      The speaker package works independently.\n\n")
}

# Show what benchmarks require parselmouth
cat("Benchmarks requiring parselmouth:\n")
cat("  • 05_converted_scripts_comparison.R (Praat script comparisons)\n")
cat("\nBenchmarks that work without parselmouth:\n")
cat("  • 01_matrix_operations.R (SIMD matrix ops)\n")
cat("  • 02_data_conversion.R (Sound conversion)\n")
cat("  • 03_tone_generation.R (Synthetic audio)\n")
cat("  • 06_phase2_intensity.R (Audio analysis)\n")
cat("  • All other benchmarks\n\n")
