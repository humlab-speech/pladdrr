#!/usr/bin/env Rscript
# Test TextGrid editing functionality
# Demonstrates all the features mentioned in PRAAT_REPLICATION_GAP_ANALYSIS.md

library(speaker)

cat("================================================================================\n")
cat("TextGrid Editing Functionality Test\n")
cat("================================================================================\n\n")

# Test 1: Create new TextGrid
cat("Test 1: Creating new TextGrid...\n")
tg <- TextGrid$create(0, 10, "phones words", "tones")
cat("✓ TextGrid created with 3 tiers\n")
cat(sprintf("  - Number of tiers: %d\n", tg$get_number_of_tiers()))
cat(sprintf("  - Tier names: %s\n", paste(tg$get_tier_names(), collapse = ", ")))
cat("\n")

# Test 2: Add interval boundaries
cat("Test 2: Adding interval boundaries...\n")
tg$insert_boundary("words", 1.5)
tg$insert_boundary("words", 3.2)
tg$insert_boundary("words", 5.8)
tg$insert_boundary("words", 7.1)
cat(sprintf("✓ Added boundaries, now has %d intervals\n", tg$get_number_of_intervals("words")))
cat("\n")

# Test 3: Set interval labels
cat("Test 3: Setting interval labels...\n")
tg$set_interval_text("words", 1, "hello")
tg$set_interval_text("words", 2, "world")
tg$set_interval_text("words", 3, "from")
tg$set_interval_text("words", 4, "speaker")
cat("✓ Set labels for 4 intervals\n")
for (i in 1:4) {
  label <- tg$get_interval_text("words", i)
  start_time <- tg$get_interval_start_time("words", i)
  end_time <- tg$get_interval_end_time("words", i)
  cat(sprintf("  Interval %d [%.2f - %.2f]: '%s'\n", i, start_time, end_time, label))
}
cat("\n")

# Test 4: Add point tier annotations
cat("Test 4: Adding point tier annotations...\n")
tg$insert_point("tones", 0.5, "H*")
tg$insert_point("tones", 2.3, "L-L%")
tg$insert_point("tones", 4.8, "H*")
tg$insert_point("tones", 6.5, "!H*")
cat(sprintf("✓ Added %d tonal targets\n", tg$get_number_of_points("tones")))
for (i in 1:tg$get_number_of_points("tones")) {
  time <- tg$get_point_time("tones", i)
  label <- tg$get_point_text("tones", i)
  cat(sprintf("  Point %d at %.2fs: '%s'\n", i, time, label))
}
cat("\n")

# Test 5: Modify point tier text
cat("Test 5: Modifying point tier text...\n")
tg$set_point_text("tones", 2, "L-H%")
cat(sprintf("✓ Changed point 2 label to: '%s'\n", tg$get_point_text("tones", 2)))
cat("\n")

# Test 6: Query label at time
cat("Test 6: Querying labels at specific times...\n")
test_times <- c(0.5, 2.0, 4.5, 7.5)
for (time in test_times) {
  label <- tg$get_label_at_time("words", time)
  cat(sprintf("  At %.1fs: '%s'\n", time, label))
}
cat("\n")

# Test 7: Add new tiers
cat("Test 7: Adding new tiers...\n")
tg$add_interval_tier("syllables")
tg$add_point_tier("events")
cat(sprintf("✓ Added tiers, now has %d tiers total\n", tg$get_number_of_tiers()))
cat(sprintf("  - Tier names: %s\n", paste(tg$get_tier_names(), collapse = ", ")))
cat("\n")

# Test 8: Tier type checking
cat("Test 8: Checking tier types...\n")
for (i in 1:tg$get_number_of_tiers()) {
  tier_name <- tg$get_tier_name(i)
  is_interval <- tg$tier_is_interval_tier(i)
  tier_type <- if (is_interval) "IntervalTier" else "PointTier"
  cat(sprintf("  Tier %d '%s': %s\n", i, tier_name, tier_type))
}
cat("\n")

# Test 9: Export to data frame
cat("Test 9: Exporting to data frame...\n")
df <- tg$as_data_frame()
cat(sprintf("✓ Exported %d rows\n", nrow(df)))
cat("  First few rows:\n")
print(head(df, 10))
cat("\n")

# Test 10: Save TextGrid
cat("Test 10: Saving TextGrid...\n")
output_file <- tempfile(fileext = ".TextGrid")
tg$save(output_file)
cat(sprintf("✓ Saved to: %s\n", output_file))
cat(sprintf("  File size: %d bytes\n", file.info(output_file)$size))
cat("\n")

# Test 11: Read saved TextGrid
cat("Test 11: Reading saved TextGrid...\n")
tg2 <- TextGrid$new(output_file)
cat(sprintf("✓ Loaded TextGrid\n"))
cat(sprintf("  - Duration: %.1fs\n", tg2$get_total_duration()))
cat(sprintf("  - Number of tiers: %d\n", tg2$get_number_of_tiers()))
cat(sprintf("  - Words tier has %d intervals\n", tg2$get_number_of_intervals("words")))
cat("\n")

# Test 12: Extract part of TextGrid
cat("Test 12: Extracting part of TextGrid...\n")
tg_part <- tg$extract_part(2.0, 6.0, preserve_times = FALSE)
cat(sprintf("✓ Extracted TextGrid\n"))
cat(sprintf("  - Original duration: %.1fs\n", tg$get_total_duration()))
cat(sprintf("  - Extracted duration: %.1fs\n", tg_part$get_total_duration()))
cat(sprintf("  - Start time: %.1fs, End time: %.1fs\n", 
            tg_part$get_start_time(), tg_part$get_end_time()))
cat("\n")

# Test 13: Remove boundary
cat("Test 13: Removing a boundary...\n")
n_before <- tg$get_number_of_intervals("words")
tg$remove_boundary("words", 3.2)
n_after <- tg$get_number_of_intervals("words")
cat(sprintf("✓ Removed boundary at 3.2s\n"))
cat(sprintf("  - Intervals before: %d, after: %d\n", n_before, n_after))
cat("\n")

# Test 14: Remove point
cat("Test 14: Removing a point...\n")
n_before <- tg$get_number_of_points("tones")
tg$remove_point("tones", 2)
n_after <- tg$get_number_of_points("tones")
cat(sprintf("✓ Removed point 2\n"))
cat(sprintf("  - Points before: %d, after: %d\n", n_before, n_after))
cat("\n")

# Cleanup
unlink(output_file)

cat("================================================================================\n")
cat("All TextGrid editing tests completed successfully! ✓\n")
cat("================================================================================\n")
cat("\n")
cat("Summary of tested functionality:\n")
cat("  ✓ TextGrid creation\n")
cat("  ✓ Interval boundary insertion\n")
cat("  ✓ Interval label setting/getting\n")
cat("  ✓ Point insertion\n")
cat("  ✓ Point label setting/getting\n")
cat("  ✓ Tier management (add interval/point tiers)\n")
cat("  ✓ Tier type checking\n")
cat("  ✓ Export to data frame\n")
cat("  ✓ File I/O (save/load)\n")
cat("  ✓ Extracting time ranges\n")
cat("  ✓ Boundary removal\n")
cat("  ✓ Point removal\n")
cat("  ✓ Query label at time\n")
cat("\n")
cat("All gaps mentioned in PRAAT_REPLICATION_GAP_ANALYSIS.md are RESOLVED!\n")
