#' Cross-Validation Test Suite
#'
#' Tests that all implementations (Praat scripts, Python/plabench, R/pladdrr)
#' return identical results within numerical tolerance.
#'
#' Requires:
#' - Praat executable at /Applications/Praat.app/Contents/MacOS/Praat
#' - plabench Python package installed
#' - speakr R package (optional, for direct Praat script calling)

library(testthat)
library(pladdrr)

# Skip this entire file on CRAN - requires external dependencies
if (!interactive() && !identical(Sys.getenv("NOT_CRAN"), "true")) {
  exit_file("Skipping cross-validation tests on CRAN (requires external deps)")
}

# Test configuration
PRAAT_EXEC <- "/Applications/Praat.app/Contents/MacOS/Praat"
PLABENCH_DIR <- "/Users/frkkan96/Documents/src/plabench"
PRAAT_SCRIPTS_DIR <- file.path(PLABENCH_DIR)
TEST_DATA_DIR <- file.path(PLABENCH_DIR, "signalfiles")

# Numerical tolerance for comparison
TOLERANCE <- list(
  avqi = 0.01,      # AVQI score
  cpps = 0.1,       # dB
  hnr = 0.1,        # dB
  shimmer = 0.01,   # %
  slope = 0.1,      # dB
  tilt = 0.1,       # dB
  dsi = 0.01,       # DSI score
  mpt = 0.1,        # seconds
  i_low = 0.5,      # dB
  f0_high = 1.0,    # Hz
  jitter = 0.001,   # %
  tremor_f = 0.1,   # Hz
  tremor_i = 1.0    # %
)

#' Execute Praat script and capture output
#' @keywords internal
run_praat_script <- function(script_path, ...) {
  args <- c("--utf8", "--run", script_path, ...)

  result <- system2(
    PRAAT_EXEC,
    args = args,
    stdout = TRUE,
    stderr = TRUE
  )

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop("Praat script failed: ", paste(result, collapse = "\n"))
  }

  return(result)
}

#' Execute Python/plabench code and capture output
#' @keywords internal
run_python_plabench <- function(code) {
  temp_script <- tempfile(fileext = ".py")
  writeLines(code, temp_script)

  result <- system2(
    "python3",
    args = c(temp_script),
    stdout = TRUE,
    stderr = TRUE
  )

  unlink(temp_script)

  if (!is.null(attr(result, "status")) && attr(result, "status") != 0) {
    stop("Python script failed: ", paste(result, collapse = "\n"))
  }

  return(result)
}

#' Parse Praat AVQI output
#' @keywords internal
parse_praat_avqi <- function(output) {
  # Parse CSV output from Praat AVQI script
  # Expected format: AVQI,CPPS,HNR,ShimmerLocal,ShimmerLocalDB,Slope,Tilt

  csv_lines <- grep("^[0-9]", output, value = TRUE)
  if (length(csv_lines) == 0) {
    stop("No AVQI results found in Praat output")
  }

  values <- as.numeric(strsplit(csv_lines[1], ",")[[1]])

  list(
    avqi = values[1],
    cpps = values[2],
    hnr = values[3],
    shimmer_local = values[4],
    shimmer_local_db = values[5],
    slope = values[6],
    tilt = values[7]
  )
}

#' Parse Python AVQI output
#' @keywords internal
parse_python_avqi <- function(output) {
  # Parse JSON output from Python script
  json_line <- grep("\\{", output, value = TRUE)[1]
  result <- jsonlite::fromJSON(json_line)

  list(
    avqi = result$avqi,
    cpps = result$cpps,
    hnr = result$hnr,
    shimmer_local = result$shimmer_local,
    shimmer_local_db = result$shimmer_db,
    slope = result$slope,
    tilt = result$tilt
  )
}

#' Check if Praat executable exists
#' @keywords internal
praat_available <- function() {
  file.exists(PRAAT_EXEC)
}

#' Check if plabench is available
#' @keywords internal
plabench_available <- function() {
  result <- system2("python3", args = c("-c", "import plabench"),
                   stdout = FALSE, stderr = FALSE)
  return(result == 0)
}

# =============================================================================
# AVQI Cross-Validation Tests
# =============================================================================

test_that("AVQI v3.01: R/pladdrr vs Python/plabench", {
  skip_if_not(plabench_available(), "plabench not available")

  avqi_test_dir <- file.path(TEST_DATA_DIR, "AVQI", "input")
  skip_if_not(dir.exists(avqi_test_dir), "AVQI test data not found")

  cs_files <- list.files(avqi_test_dir, pattern = "^cs.*\\.wav$", full.names = TRUE)
  sv_files <- list.files(avqi_test_dir, pattern = "^sv.*\\.wav$", full.names = TRUE)

  skip_if(length(cs_files) == 0 || length(sv_files) == 0,
          "AVQI test files not found")

  # Run R/pladdrr implementation
  cat("\n[R/pladdrr] Running AVQI...\n")
  r_result <- compute_avqi(
    sound = sv_files[1],
    type = "combined",
    speech_sound = cs_files[1],
    verbose = FALSE
  )

  # Run Python/plabench implementation
  cat("[Python] Running AVQI...\n")
  python_code <- sprintf('
import json
from plabench.avqi import calculate_avqi

result = calculate_avqi(
    cs_files=["%s"],
    sv_files=["%s"],
    version="v3.01"
)

print(json.dumps({
    "avqi": result.avqi,
    "cpps": result.cpps,
    "hnr": result.hnr,
    "shimmer_local": result.shimmer_local,
    "shimmer_db": result.shimmer_db,
    "slope": result.slope,
    "tilt": result.tilt
}))
', cs_files[1], sv_files[1])

  python_output <- run_python_plabench(python_code)
  python_result <- parse_python_avqi(python_output)

  # Compare results
  cat("\n=== AVQI Comparison ===\n")
  cat(sprintf("AVQI:        R=%.3f  Python=%.3f  Diff=%.3f\n",
              r_result$avqi, python_result$avqi,
              abs(r_result$avqi - python_result$avqi)))
  cat(sprintf("CPPS:        R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$cpps, python_result$cpps,
              abs(r_result$cpps - python_result$cpps)))
  cat(sprintf("HNR:         R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$hnr, python_result$hnr,
              abs(r_result$hnr - python_result$hnr)))
  cat(sprintf("Shimmer:     R=%.2f  Python=%.2f  Diff=%.2f%%\n",
              r_result$shimmer_local, python_result$shimmer_local,
              abs(r_result$shimmer_local - python_result$shimmer_local)))
  cat(sprintf("Shimmer dB:  R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$shimmer_local_db, python_result$shimmer_local_db,
              abs(r_result$shimmer_local_db - python_result$shimmer_local_db)))
  cat(sprintf("Slope:       R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$slope, python_result$slope,
              abs(r_result$slope - python_result$slope)))
  cat(sprintf("Tilt:        R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$tilt, python_result$tilt,
              abs(r_result$tilt - python_result$tilt)))

  # Assertions with tolerance
  expect_equal(r_result$avqi, python_result$avqi, tolerance = TOLERANCE$avqi)
  expect_equal(r_result$cpps, python_result$cpps, tolerance = TOLERANCE$cpps)
  expect_equal(r_result$hnr, python_result$hnr, tolerance = TOLERANCE$hnr)
  expect_equal(r_result$shimmer_local, python_result$shimmer_local,
               tolerance = TOLERANCE$shimmer)
  expect_equal(r_result$shimmer_local_db, python_result$shimmer_local_db,
               tolerance = TOLERANCE$shimmer)
  expect_equal(r_result$slope, python_result$slope, tolerance = TOLERANCE$slope)
  expect_equal(r_result$tilt, python_result$tilt, tolerance = TOLERANCE$tilt)
})

test_that("AVQI v3.01: R/pladdrr vs Praat script", {
  skip_if_not(praat_available(), "Praat not available")
  skip("Praat AVQI script needs output format modification for parsing")

  # This test requires modifying the Praat AVQI script to output
  # results in a parseable format (CSV or JSON)
})

# =============================================================================
# DSI Cross-Validation Tests
# =============================================================================

test_that("DSI v2.01: R/pladdrr vs Python/plabench", {
  skip_if_not(plabench_available(), "plabench not available")

  dsi_test_dir <- file.path(TEST_DATA_DIR, "DSI", "input")
  skip_if_not(dir.exists(dsi_test_dir), "DSI test data not found")

  mpt_files <- list.files(dsi_test_dir, pattern = "^mpt.*\\.wav$", full.names = TRUE)
  fh_files <- list.files(dsi_test_dir, pattern = "^fh.*\\.wav$", full.names = TRUE)
  im_files <- list.files(dsi_test_dir, pattern = "^im.*\\.wav$", full.names = TRUE)
  ppq_files <- list.files(dsi_test_dir, pattern = "^ppq.*\\.wav$", full.names = TRUE)

  skip_if(length(mpt_files) == 0 || length(fh_files) == 0 ||
          length(im_files) == 0 || length(ppq_files) == 0,
          "DSI test files not found")

  # Run R/pladdrr implementation
  cat("\n[R/pladdrr] Running DSI...\n")

  # Load and concatenate files
  mpt_sound <- Sound$new(mpt_files[1])
  for (i in seq_along(mpt_files)[-1]) {
    mpt_sound <- mpt_sound$concatenate(Sound$new(mpt_files[i]))
  }

  fh_sound <- Sound$new(fh_files[1])
  for (i in seq_along(fh_files)[-1]) {
    fh_sound <- fh_sound$concatenate(Sound$new(fh_files[i]))
  }

  im_sound <- Sound$new(im_files[1])
  for (i in seq_along(im_files)[-1]) {
    im_sound <- im_sound$concatenate(Sound$new(im_files[i]))
  }

  ppq_sound <- Sound$new(ppq_files[1])
  for (i in seq_along(ppq_files)[-1]) {
    ppq_sound <- ppq_sound$concatenate(Sound$new(ppq_files[i]))
  }

  # Combine all into one sound for DSI calculation
  combined_sound <- mpt_sound$concatenate(fh_sound)
  combined_sound <- combined_sound$concatenate(im_sound)
  combined_sound <- combined_sound$concatenate(ppq_sound)

  r_result <- compute_dsi(
    sound = combined_sound,
    type = "sustained",
    verbose = FALSE
  )

  # Run Python/plabench implementation
  cat("[Python] Running DSI...\n")
  python_code <- sprintf('
import json
from plabench.dsi import calculate_dsi

result = calculate_dsi(
    mpt_files=["%s"],
    fh_files=["%s"],
    im_files=["%s"],
    ppq_files=["%s"]
)

print(json.dumps({
    "dsi": result.dsi,
    "mpt": result.mpt,
    "i_low": result.i_low,
    "f0_high": result.f0_high,
    "jitter_ppq5": result.jitter_ppq5
}))
',
    paste(mpt_files, collapse = '","'),
    paste(fh_files, collapse = '","'),
    paste(im_files, collapse = '","'),
    paste(ppq_files, collapse = '","')
  )

  python_output <- run_python_plabench(python_code)
  json_line <- grep("\\{", python_output, value = TRUE)[1]
  python_result <- jsonlite::fromJSON(json_line)

  # Compare results
  cat("\n=== DSI Comparison ===\n")
  cat(sprintf("DSI:         R=%.2f  Python=%.2f  Diff=%.2f\n",
              r_result$dsi, python_result$dsi,
              abs(r_result$dsi - python_result$dsi)))
  cat(sprintf("MPT:         R=%.2f  Python=%.2f  Diff=%.2f s\n",
              r_result$mpt, python_result$mpt,
              abs(r_result$mpt - python_result$mpt)))
  cat(sprintf("I-low:       R=%.2f  Python=%.2f  Diff=%.2f dB\n",
              r_result$i_low, python_result$i_low,
              abs(r_result$i_low - python_result$i_low)))
  cat(sprintf("F0-high:     R=%.1f  Python=%.1f  Diff=%.1f Hz\n",
              r_result$f0_high, python_result$f0_high,
              abs(r_result$f0_high - python_result$f0_high)))
  cat(sprintf("Jitter ppq5: R=%.3f  Python=%.3f  Diff=%.3f%%\n",
              r_result$jitter_ppq5, python_result$jitter_ppq5,
              abs(r_result$jitter_ppq5 - python_result$jitter_ppq5)))

  # Assertions
  expect_equal(r_result$dsi, python_result$dsi, tolerance = TOLERANCE$dsi)
  expect_equal(r_result$mpt, python_result$mpt, tolerance = TOLERANCE$mpt)
  expect_equal(r_result$i_low, python_result$i_low, tolerance = TOLERANCE$i_low)
  expect_equal(r_result$f0_high, python_result$f0_high, tolerance = TOLERANCE$f0_high)
  expect_equal(r_result$jitter_ppq5, python_result$jitter_ppq5,
               tolerance = TOLERANCE$jitter)
})

# =============================================================================
# Tremor Cross-Validation Tests
# =============================================================================

test_that("Tremor v3.05: R/pladdrr vs Python/plabench", {
  skip_if_not(plabench_available(), "plabench not available")
  skip("Tremor test audio file needed")

  tremor_file <- file.path(TEST_DATA_DIR, "tremor", "sustained_vowel.wav")
  skip_if_not(file.exists(tremor_file), "Tremor test file not found")

  # Run R/pladdrr implementation
  cat("\n[R/pladdrr] Running Tremor...\n")
  r_result <- analyze_tremor(tremor_file, verbose = FALSE)

  # Run Python/plabench implementation
  cat("[Python] Running Tremor...\n")
  python_code <- sprintf('
import json
from plabench.tremor import analyze_tremor

result = analyze_tremor("%s")

print(json.dumps({
    "FTrF": result.FTrF,
    "FTrI": result.FTrI,
    "FTrC": result.FTrC,
    "FCoHNR": result.FCoHNR,
    "ATrF": result.ATrF,
    "ATrI": result.ATrI,
    "ATrC": result.ATrC,
    "ACoHNR": result.ACoHNR
}))
', tremor_file)

  python_output <- run_python_plabench(python_code)
  json_line <- grep("\\{", python_output, value = TRUE)[1]
  python_result <- jsonlite::fromJSON(json_line)

  # Compare results
  cat("\n=== Tremor Comparison ===\n")
  cat(sprintf("FTrF:   R=%.2f  Python=%.2f  Diff=%.2f Hz\n",
              r_result$FTrF, python_result$FTrF,
              abs(r_result$FTrF - python_result$FTrF)))
  cat(sprintf("FTrI:   R=%.2f  Python=%.2f  Diff=%.2f%%\n",
              r_result$FTrI, python_result$FTrI,
              abs(r_result$FTrI - python_result$FTrI)))
  cat(sprintf("ATrF:   R=%.2f  Python=%.2f  Diff=%.2f Hz\n",
              r_result$ATrF, python_result$ATrF,
              abs(r_result$ATrF - python_result$ATrF)))
  cat(sprintf("ATrI:   R=%.2f  Python=%.2f  Diff=%.2f%%\n",
              r_result$ATrI, python_result$ATrI,
              abs(r_result$ATrI - python_result$ATrI)))

  # Assertions
  expect_equal(r_result$FTrF, python_result$FTrF, tolerance = TOLERANCE$tremor_f)
  expect_equal(r_result$FTrI, python_result$FTrI, tolerance = TOLERANCE$tremor_i)
  expect_equal(r_result$ATrF, python_result$ATrF, tolerance = TOLERANCE$tremor_f)
  expect_equal(r_result$ATrI, python_result$ATrI, tolerance = TOLERANCE$tremor_i)
})

test_that("Tremor v3.05: R/pladdrr vs Praat script", {
  skip_if_not(praat_available(), "Praat not available")
  skip("Requires Praat tremor.praat script wrapper")

  # This would require creating a wrapper script for tremor.praat
  # that outputs results in parseable format
})

# =============================================================================
# Speakr Integration Tests
# =============================================================================

test_that("speakr package can call Praat scripts", {
  skip_if_not_installed("speakr")

  library(speakr)

  # Test basic Praat script execution via speakr
  test_script <- tempfile(fileext = ".praat")
  writeLines(c(
    'writeInfoLine: "Hello from Praat"',
    'appendInfoLine: "Version: ", praatVersion$'
  ), test_script)

  result <- praat(test_script, capture = TRUE)

  expect_true(grepl("Hello from Praat", result))
  expect_true(grepl("Version:", result))

  unlink(test_script)
})

# =============================================================================
# Helper function to run all cross-validation tests
# =============================================================================

#' Run all cross-validation tests and generate report
#' @export
run_cross_validation <- function() {
  cat("=============================================================\n")
  cat("PLABENCH CROSS-VALIDATION TEST SUITE\n")
  cat("=============================================================\n\n")

  cat("Checking prerequisites...\n")
  cat(sprintf("  Praat:    %s\n", ifelse(praat_available(), "✓", "✗")))
  cat(sprintf("  plabench: %s\n", ifelse(plabench_available(), "✓", "✗")))
  cat(sprintf("  speakr:   %s\n",
              ifelse(requireNamespace("speakr", quietly = TRUE), "✓", "✗")))
  cat("\n")

  cat("Running tests...\n\n")

  test_dir("tests", reporter = "progress")

  cat("\n=============================================================\n")
  cat("Cross-validation complete!\n")
  cat("=============================================================\n")
}
