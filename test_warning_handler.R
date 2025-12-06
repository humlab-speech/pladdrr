#!/usr/bin/env Rscript
# Test script for Melder warning handler fix
# Tests that extract_intervals_where doesn't segfault when no matches found

library(pladdrr)

cat("Testing Sound$extract_intervals_where with no matching intervals...\n\n")

# Load test sound
s <- Sound$new('tests/testthat/fixtures/speech_sample.wav')
cat("✓ Sound loaded\n")

# Create pitch
p <- s$to_pitch()
cat("✓ Pitch extracted\n")

# Create voiced/unvoiced TextGrid
tg <- p$to_textgrid_vuv()
cat("✓ TextGrid created\n")

# Check tier contents
cat("\nTextGrid tier 1 contents:\n")
n_intervals <- tg$get_number_of_intervals(1)
cat(sprintf("  Number of intervals: %d\n", n_intervals))
for (i in 1:min(5, n_intervals)) {
  label <- tg$get_interval_text(1, i)
  cat(sprintf("  Interval %d: '%s'\n", i, label))
}

# TEST CASE 1: Search for existing label (should work)
cat("\n--- Test 1: Search for 'U' (should find matches) ---\n")
result1 <- s$extract_intervals_where(tg, 1, "is equal to", "U", FALSE)
cat(sprintf("✓ Found %d intervals with label 'U'\n", length(result1)))

# TEST CASE 2: Search for non-existent label (previously segfaulted)
cat("\n--- Test 2: Search for 'V' (should return empty, no crash) ---\n")
result2 <- s$extract_intervals_where(tg, 1, "is equal to", "V", FALSE)
cat(sprintf("✓ Found %d intervals with label 'V' (no crash!)\n", length(result2)))

# TEST CASE 3: Another non-existent label
cat("\n--- Test 3: Search for 'XYZ' (should return empty, no crash) ---\n")
result3 <- s$extract_intervals_where(tg, 1, "is equal to", "XYZ", FALSE)
cat(sprintf("✓ Found %d intervals with label 'XYZ' (no crash!)\n", length(result3)))

cat("\n✅ All tests passed! Warning handler successfully prevents segfault.\n")
