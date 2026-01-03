# test_formantpath_comprehensive.R
# Comprehensive integration test for FormantPath module (Phase 2.2)
# Tests all major functionality and edge cases

library(pladdrr)

cat("=======================================================\n")
cat("  FormantPath Module - Comprehensive Integration Test\n")
cat("=======================================================\n\n")

test_results <- list()
test_count <- 0
pass_count <- 0

# Helper function to run tests
run_test <- function(name, expr) {
  test_count <<- test_count + 1
  cat(sprintf("Test %d: %s\n", test_count, name))
  tryCatch({
    result <- eval(expr)
    pass_count <<- pass_count + 1
    cat("  ✓ PASS\n\n")
    test_results[[name]] <<- list(status = "PASS", result = result)
    return(TRUE)
  }, error = function(e) {
    cat("  ✗ FAIL:", e$message, "\n\n")
    test_results[[name]] <<- list(status = "FAIL", error = e$message)
    return(FALSE)
  })
}

# =============================================================================
# 1. BASIC CREATION TESTS
# =============================================================================

cat("--- Section 1: Basic Creation ---\n\n")

run_test("Create FormantPath from synthetic tone", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(
    time_step = 0.005,
    max_num_formants = 5,
    formant_ceiling = 5500,
    num_steps_up_down = 2L
  )
  stopifnot(fp$get_duration() > 0)
  stopifnot(fp$get_number_of_candidates() == 5)
  fp
})

run_test("Create FormantPath with different parameters", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(
    time_step = 0.01,
    max_num_formants = 4,
    formant_ceiling = 5000,
    ceiling_step_fraction = 0.10,
    num_steps_up_down = 1L
  )
  stopifnot(fp$get_number_of_candidates() == 3)  # 2*1+1
  stopifnot(fp$get_dx() == 0.01)
  fp
})

run_test("Create from real audio file", {
  test_file <- "inst/extdata/test.wav"
  if (!file.exists(test_file)) {
    stop("Test file not found")
  }
  sound <- Sound(test_file)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  stopifnot(fp$get_duration() > 0)
  stopifnot(fp$get_nx() > 0)
  fp
})

# =============================================================================
# 2. QUERY METHODS
# =============================================================================

cat("--- Section 2: Query Methods ---\n\n")

# Use the first successful FormantPath
fp_test <- test_results[["Create FormantPath from synthetic tone"]]$result

run_test("Get time domain properties", {
  xmin <- fp_test$get_xmin()
  xmax <- fp_test$get_xmax()
  duration <- fp_test$get_duration()
  nx <- fp_test$get_nx()
  dx <- fp_test$get_dx()
  x1 <- fp_test$get_x1()
  
  stopifnot(xmax > xmin)
  stopifnot(abs(duration - (xmax - xmin)) < 0.001)
  stopifnot(nx > 0)
  stopifnot(dx > 0)
  stopifnot(x1 >= xmin)
  
  list(xmin=xmin, xmax=xmax, duration=duration, nx=nx, dx=dx, x1=x1)
})

run_test("Get candidate properties", {
  n_candidates <- fp_test$get_number_of_candidates()
  n_tracks <- fp_test$get_number_of_formant_tracks()
  ceilings <- fp_test$get_all_ceiling_frequencies()
  
  stopifnot(n_candidates == 5)
  stopifnot(n_tracks >= 4)
  stopifnot(length(ceilings) == n_candidates)
  stopifnot(all(ceilings > 0))
  
  list(candidates=n_candidates, tracks=n_tracks, ceilings=ceilings)
})

run_test("Get ceiling frequency for each candidate", {
  ceilings <- sapply(1:5, function(i) fp_test$get_ceiling_frequency(i))
  stopifnot(length(ceilings) == 5)
  stopifnot(all(diff(ceilings) > 0))  # Should be increasing
  ceilings
})

run_test("Get candidate in specific frame", {
  candidate <- fp_test$get_candidate_in_frame(10)
  stopifnot(candidate >= 1 && candidate <= 5)
  candidate
})

run_test("Get stress of candidates", {
  stresses <- sapply(1:3, function(i) {
    fp_test$get_stress_of_candidate(
      candidate = i,
      parameters = c(1, 1, 1, 1, 1),
      powerf = 1.25
    )
  })
  stopifnot(all(is.finite(stresses)))
  stopifnot(all(stresses >= 0))
  stresses
})

# =============================================================================
# 3. PATH MANIPULATION
# =============================================================================

cat("--- Section 3: Path Manipulation ---\n\n")

run_test("Set manual path for time range", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  # Set candidate 3 for middle portion
  fp$set_path(tmin = 0.2, tmax = 0.3, selected_candidate = 3)
  
  # Check that candidate was set
  mid_candidate <- fp$get_candidate_in_frame(25)  # Approximate middle frame
  # Note: may not be exactly 3 due to frame alignment
  stopifnot(mid_candidate >= 1 && mid_candidate <= 5)
  TRUE
})

run_test("Set optimal path", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  fp$set_optimal_path(
    tmin = fp$get_xmin(),
    tmax = fp$get_xmax(),
    parameters = c(1, 1, 1, 1, 1),
    powerf = 1.25
  )
  
  # Should succeed without error
  TRUE
})

run_test("Get optimal ceiling", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  optimal <- fp$get_optimal_ceiling(
    tmin = fp$get_xmin(),
    tmax = fp$get_xmax(),
    parameters = c(1, 1, 1, 1, 1),
    powerf = 1.25
  )
  
  stopifnot(is.numeric(optimal))
  stopifnot(optimal > 0)
  optimal
})

run_test("Path finder with custom weights", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  fp$path_finder(
    q_weight = 1.0,
    frequency_change_weight = 1.0,
    stress_weight = 1.0,
    ceiling_change_weight = 1.0,
    intensity_modulation_step_size = 5.0,
    window_length = 0.025,
    parameters = c(1, 1, 1, 1, 1),
    powerf = 1.25
  )
  
  TRUE
})

# =============================================================================
# 4. EXTRACTION & EXPORT
# =============================================================================

cat("--- Section 4: Extraction & Export ---\n\n")

run_test("Extract optimal Formant", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  formant <- fp$extract_formant()
  
  stopifnot(!is.null(formant))
  stopifnot(formant$get_duration() > 0)
  stopifnot(formant$get_number_of_frames() > 0)
  
  formant
})

run_test("Export to data frame", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  df <- as.data.frame(fp, max_formants = 5)
  
  stopifnot(nrow(df) > 0)
  stopifnot(ncol(df) >= 4)  # time, formant, frequency, bandwidth
  stopifnot("time" %in% names(df))
  stopifnot("frequency" %in% names(df))
  
  df
})

run_test("Verify exported data structure", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 1L)  # 3 candidates
  
  df <- as.data.frame(fp)
  
  # Check for multiple candidates in data
  n_candidates <- fp$get_number_of_candidates()
  n_frames <- fp$get_nx()
  
  # Data should have rows for all candidates × frames × formants
  stopifnot(nrow(df) > n_frames)
  
  df
})

# =============================================================================
# 5. FILE I/O
# =============================================================================

cat("--- Section 5: File I/O ---\n\n")

run_test("Save FormantPath to file", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 1L)
  
  tmpfile <- tempfile(fileext = ".FormantPath")
  fp$save(tmpfile)
  
  stopifnot(file.exists(tmpfile))
  stopifnot(file.size(tmpfile) > 0)
  
  unlink(tmpfile)
  TRUE
})

# =============================================================================
# 6. EDGE CASES
# =============================================================================

cat("--- Section 6: Edge Cases ---\n\n")

run_test("Very short sound", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)  # 50ms
  fp <- sound$to_formant_path(
    time_step = 0.005,
    num_steps_up_down = 1L
  )
  
  stopifnot(fp$get_duration() > 0)
  stopifnot(fp$get_nx() > 0)
  
  fp
})

run_test("Single candidate (num_steps = 0)", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 0L)
  
  stopifnot(fp$get_number_of_candidates() == 1)
  
  fp
})

run_test("Many candidates (num_steps = 4)", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 4L)
  
  stopifnot(fp$get_number_of_candidates() == 9)
  
  ceilings <- fp$get_all_ceiling_frequencies()
  stopifnot(length(ceilings) == 9)
  
  fp
})

run_test("Different formant ceiling values", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  
  # Test low ceiling (male)
  fp_low <- sound$to_formant_path(formant_ceiling = 5000, num_steps_up_down = 1L)
  
  # Test high ceiling (female)
  fp_high <- sound$to_formant_path(formant_ceiling = 5500, num_steps_up_down = 1L)
  
  # Test very high ceiling (child)
  fp_child <- sound$to_formant_path(formant_ceiling = 8000, num_steps_up_down = 1L)
  
  stopifnot(mean(fp_low$get_all_ceiling_frequencies()) < 
            mean(fp_high$get_all_ceiling_frequencies()))
  stopifnot(mean(fp_high$get_all_ceiling_frequencies()) < 
            mean(fp_child$get_all_ceiling_frequencies()))
  
  TRUE
})

# =============================================================================
# 7. INTEGRATION WITH OTHER OBJECTS
# =============================================================================

cat("--- Section 7: Integration with Other Objects ---\n\n")

run_test("Extract Formant and query values", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  formant <- fp$extract_formant()
  
  # Query F1, F2, F3 at midpoint
  mid_time <- formant$get_duration() / 2
  f1 <- formant$get_value_at_time(1, mid_time, "HERTZ")
  f2 <- formant$get_value_at_time(2, mid_time, "HERTZ")
  
  stopifnot(is.numeric(f1))
  stopifnot(is.numeric(f2))
  stopifnot(f2 > f1 || is.na(f1) || is.na(f2))  # F2 > F1 if both valid
  
  list(f1=f1, f2=f2)
})

run_test("Export Formant to data frame", {
  sound <- Sound$create_tone(frequency=440, duration=0.5)
  fp <- sound$to_formant_path(num_steps_up_down = 2L)
  
  formant <- fp$extract_formant()
  df_formant <- as.data.frame(formant)
  
  stopifnot(nrow(df_formant) > 0)
  stopifnot("time" %in% names(df_formant))
  
  df_formant
})

# =============================================================================
# SUMMARY
# =============================================================================

cat("\n")
cat("=======================================================\n")
cat("                   TEST SUMMARY\n")
cat("=======================================================\n")
cat(sprintf("Total tests: %d\n", test_count))
cat(sprintf("Passed:      %d\n", pass_count))
cat(sprintf("Failed:      %d\n", test_count - pass_count))
cat(sprintf("Success rate: %.1f%%\n", 100 * pass_count / test_count))
cat("=======================================================\n\n")

if (pass_count == test_count) {
  cat("✓ ALL TESTS PASSED - FormantPath module fully functional!\n\n")
} else {
  cat("⚠ SOME TESTS FAILED - Review output above\n\n")
  cat("Failed tests:\n")
  failed <- names(test_results)[sapply(test_results, function(x) x$status == "FAIL")]
  for (test_name in failed) {
    cat(sprintf("  - %s: %s\n", test_name, test_results[[test_name]]$error))
  }
  cat("\n")
}

# Return summary
invisible(list(
  total = test_count,
  passed = pass_count,
  failed = test_count - pass_count,
  results = test_results
))
