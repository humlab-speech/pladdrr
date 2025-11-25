# TextGrid Editing Demonstration
# This example demonstrates the comprehensive TextGrid editing capabilities
# of the speaker package, addressing the critical gaps identified in the
# Praat Replication Gap Analysis

library(speaker)

# ============================================================================
# PART 1: Reading and Querying TextGrid
# ============================================================================

cat("PART 1: Reading and Querying TextGrid\n")
cat("=====================================\n\n")

# Read existing TextGrid (using the 1-minute benchmark file)
tg_path <- system.file("extdata", "benchmarkdata1min.TextGrid", package = "speaker")
if (tg_path == "") {
  stop("Benchmark TextGrid not found in package")
}

tg <- TextGrid$new(tg_path)
print(tg)

cat("\nTier names:", paste(tg$get_tier_names(), collapse = ", "), "\n")

# Query first tier information
tier1_name <- tg$get_tier_name(1)
cat("\nFirst tier:", tier1_name, "\n")

if (tg$tier_is_interval_tier(1)) {
  n_intervals <- tg$get_number_of_intervals(1)
  cat("Number of intervals in tier 1:", n_intervals, "\n")
  
  # Show first 5 intervals
  cat("\nFirst 5 intervals:\n")
  for (i in 1:min(5, n_intervals)) {
    start_t <- tg$get_interval_start_time(1, i)
    end_t <- tg$get_interval_end_time(1, i)
    label <- tg$get_interval_text(1, i)
    cat(sprintf("  Interval %d: [%.3f - %.3f] '%s'\n", i, start_t, end_t, label))
  }
}

# ============================================================================
# PART 2: Creating New TextGrid with Interval and Point Tiers
# ============================================================================

cat("\n\nPART 2: Creating New TextGrid\n")
cat("==============================\n\n")

# Create a new TextGrid with mixed tier types
# "phones words" will be interval tiers
# "tones" will be a point tier
tg_new <- TextGrid$create(0, 5, "phones words", "tones")
print(tg_new)

# ============================================================================
# PART 3: Editing Interval Tiers
# ============================================================================

cat("\n\nPART 3: Editing Interval Tiers\n")
cat("===============================\n\n")

# Insert boundaries to create intervals in the "phones" tier
cat("Inserting boundaries in 'phones' tier...\n")
tg_new$insert_boundary("phones", 0.5)
tg_new$insert_boundary("phones", 1.0)
tg_new$insert_boundary("phones", 1.3)
tg_new$insert_boundary("phones", 1.8)
tg_new$insert_boundary("phones", 2.5)

# Set interval labels
cat("Setting interval labels...\n")
tg_new$set_interval_text("phones", 1, "")      # silence
tg_new$set_interval_text("phones", 2, "h")
tg_new$set_interval_text("phones", 3, "ɛ")
tg_new$set_interval_text("phones", 4, "l")
tg_new$set_interval_text("phones", 5, "oʊ")
tg_new$set_interval_text("phones", 6, "")      # silence

# Insert boundaries in "words" tier
cat("Inserting boundaries in 'words' tier...\n")
tg_new$insert_boundary("words", 0.5)
tg_new$insert_boundary("words", 2.5)

# Set word labels
tg_new$set_interval_text("words", 1, "")
tg_new$set_interval_text("words", 2, "hello")
tg_new$set_interval_text("words", 3, "")

cat("\nCurrent state of TextGrid:\n")
print(tg_new)

# Query what we just created
cat("\nPhone intervals:\n")
n_phones <- tg_new$get_number_of_intervals("phones")
for (i in 1:n_phones) {
  start_t <- tg_new$get_interval_start_time("phones", i)
  end_t <- tg_new$get_interval_end_time("phones", i)
  label <- tg_new$get_interval_text("phones", i)
  cat(sprintf("  [%.2f - %.2f] '%s'\n", start_t, end_t, label))
}

# ============================================================================
# PART 4: Editing Point Tiers
# ============================================================================

cat("\n\nPART 4: Editing Point Tiers\n")
cat("============================\n\n")

# Insert points in the "tones" tier (e.g., ToBI tone annotations)
cat("Inserting tone points...\n")
tg_new$insert_point("tones", 1.0, "H*")      # High pitch accent
tg_new$insert_point("tones", 2.5, "L-L%")    # Low phrase and boundary tone

cat("\nTone points:\n")
n_points <- tg_new$get_number_of_points("tones")
for (i in 1:n_points) {
  time <- tg_new$get_point_time("tones", i)
  mark <- tg_new$get_point_text("tones", i)
  cat(sprintf("  Time %.2f: '%s'\n", time, mark))
}

# Modify a point label
cat("\nModifying first tone point...\n")
tg_new$set_point_text("tones", 1, "H*+L")  # Change to bitonal accent
cat("Updated label:", tg_new$get_point_text("tones", 1), "\n")

# ============================================================================
# PART 5: Tier Management
# ============================================================================

cat("\n\nPART 5: Tier Management\n")
cat("========================\n\n")

# Add a new interval tier
cat("Adding new 'syllables' tier...\n")
tg_new$add_interval_tier("syllables")

# Add a new point tier
cat("Adding new 'events' point tier...\n")
tg_new$add_point_tier("events")

cat("\nTextGrid after adding tiers:\n")
print(tg_new)

# Set tier name
cat("\nRenaming 'events' to 'landmarks'...\n")
tg_new$set_tier_name("events", "landmarks")
cat("New tier names:", paste(tg_new$get_tier_names(), collapse = ", "), "\n")

# Duplicate a tier
cat("\nDuplicating 'phones' tier to 'phones_copy'...\n")
tg_new$duplicate_tier("phones", "phones_copy")
print(tg_new)

# Remove a tier
cat("\nRemoving 'phones_copy' tier...\n")
tg_new$remove_tier("phones_copy")
cat("Remaining tiers:", paste(tg_new$get_tier_names(), collapse = ", "), "\n")

# ============================================================================
# PART 6: Boundary Manipulation
# ============================================================================

cat("\n\nPART 6: Boundary Manipulation\n")
cat("==============================\n\n")

# Query current state before modification
cat("Phones tier before boundary removal:\n")
n_phones <- tg_new$get_number_of_intervals("phones")
for (i in 1:n_phones) {
  start_t <- tg_new$get_interval_start_time("phones", i)
  end_t <- tg_new$get_interval_end_time("phones", i)
  label <- tg_new$get_interval_text("phones", i)
  cat(sprintf("  [%.2f - %.2f] '%s'\n", start_t, end_t, label))
}

# Remove a boundary to merge intervals
cat("\nRemoving boundary at 1.3s (merging 'ɛ' and 'l')...\n")
tg_new$remove_boundary("phones", 1.3)

cat("\nPhones tier after boundary removal:\n")
n_phones <- tg_new$get_number_of_intervals("phones")
for (i in 1:n_phones) {
  start_t <- tg_new$get_interval_start_time("phones", i)
  end_t <- tg_new$get_interval_end_time("phones", i)
  label <- tg_new$get_interval_text("phones", i)
  cat(sprintf("  [%.2f - %.2f] '%s'\n", start_t, end_t, label))
}

# ============================================================================
# PART 7: Point Manipulation
# ============================================================================

cat("\n\nPART 7: Point Manipulation\n")
cat("===========================\n\n")

# Add more points
tg_new$insert_point("tones", 0.8, "L+H*")
tg_new$insert_point("tones", 1.5, "!H*")

cat("Tones tier with additional points:\n")
n_points <- tg_new$get_number_of_points("tones")
for (i in 1:n_points) {
  time <- tg_new$get_point_time("tones", i)
  mark <- tg_new$get_point_text("tones", i)
  cat(sprintf("  Point %d: Time %.2f - '%s'\n", i, time, mark))
}

# Remove a point
cat("\nRemoving point 2 (was at time 1.0)...\n")
tg_new$remove_point("tones", 2)

cat("\nTones tier after removal:\n")
n_points <- tg_new$get_number_of_points("tones")
for (i in 1:n_points) {
  time <- tg_new$get_point_time("tones", i)
  mark <- tg_new$get_point_text("tones", i)
  cat(sprintf("  Point %d: Time %.2f - '%s'\n", i, time, mark))
}

# ============================================================================
# PART 8: Extraction and Export
# ============================================================================

cat("\n\nPART 8: Extraction and Export\n")
cat("==============================\n\n")

# Extract part of TextGrid (time windowing)
cat("Extracting TextGrid segment [0.5 - 2.5]...\n")
tg_segment <- tg_new$extract_part(0.5, 2.5, preserve_times = TRUE)
print(tg_segment)

# Export to data frame
cat("\nConverting to data frame...\n")
df_all <- tg_new$as_data_frame()
cat("Data frame dimensions:", nrow(df_all), "rows x", ncol(df_all), "columns\n")
cat("Column names:", paste(colnames(df_all), collapse = ", "), "\n")
cat("\nFirst 10 rows:\n")
print(head(df_all, 10))

# Export specific tiers to data frame
cat("\nExporting only 'phones' and 'words' tiers:\n")
df_selected <- tg_new$as_data_frame(tiers = c("phones", "words"))
print(head(df_selected, 10))

# Save to file
output_path <- tempfile(fileext = ".TextGrid")
cat("\nSaving TextGrid to:", output_path, "\n")
tg_new$save(output_path)
cat("File saved successfully\n")

# Verify by reading it back
tg_reloaded <- TextGrid$new(output_path)
cat("\nReloaded TextGrid:\n")
print(tg_reloaded)

# Clean up
unlink(output_path)

# ============================================================================
# PART 9: Practical Workflow Examples
# ============================================================================

cat("\n\nPART 9: Practical Workflow Examples\n")
cat("====================================\n\n")

# Example 1: VOT Analysis (protoscribe use case)
cat("Example 1: VOT (Voice Onset Time) Annotation\n")
cat("---------------------------------------------\n")

tg_vot <- TextGrid$create(0, 1.5, "segments vot")

# Annotate stop consonant
tg_vot$insert_boundary("segments", 0.3)  # Vowel starts
tg_vot$insert_boundary("segments", 0.8)  # Stop closure
tg_vot$insert_boundary("segments", 0.85) # Stop release
tg_vot$insert_boundary("segments", 1.1)  # Following vowel

tg_vot$set_interval_text("segments", 1, "")
tg_vot$set_interval_text("segments", 2, "a")
tg_vot$set_interval_text("segments", 3, "k_closure")
tg_vot$set_interval_text("segments", 4, "k_burst")
tg_vot$set_interval_text("segments", 5, "a")

# Mark VOT boundaries
tg_vot$insert_boundary("vot", 0.8)  # VOT start
tg_vot$insert_boundary("vot", 0.95) # VOT end

tg_vot$set_interval_text("vot", 1, "")
tg_vot$set_interval_text("vot", 2, "VOT")
tg_vot$set_interval_text("vot", 3, "")

cat("VOT annotation:\n")
vot_df <- tg_vot$as_data_frame(tiers = "vot")
vot_row <- vot_df[vot_df$label == "VOT", ]
if (nrow(vot_row) > 0) {
  vot_duration <- vot_row$end_time - vot_row$start_time
  cat(sprintf("  VOT duration: %.0f ms\n", vot_duration * 1000))
  cat(sprintf("  Start: %.3f s, End: %.3f s\n", vot_row$start_time, vot_row$end_time))
}

# Example 2: MOMEL/INTSINT Annotation (reindeer use case)
cat("\nExample 2: MOMEL/INTSINT Prosodic Annotation\n")
cat("---------------------------------------------\n")

tg_prosody <- TextGrid$create(0, 3, "words", "tones")

# Add word boundaries
tg_prosody$insert_boundary("words", 0.5)
tg_prosody$insert_boundary("words", 1.0)
tg_prosody$insert_boundary("words", 1.5)
tg_prosody$insert_boundary("words", 2.0)

tg_prosody$set_interval_text("words", 1, "")
tg_prosody$set_interval_text("words", 2, "I")
tg_prosody$set_interval_text("words", 3, "love")
tg_prosody$set_interval_text("words", 4, "linguistics")
tg_prosody$set_interval_text("words", 5, "")

# Add INTSINT tonal targets (point tier)
tg_prosody$insert_point("tones", 0.75, "M")  # Mid on "I"
tg_prosody$insert_point("tones", 1.25, "H")  # High on "love"
tg_prosody$insert_point("tones", 1.75, "D")  # Downstepped
tg_prosody$insert_point("tones", 2.0, "B")   # Bottom (phrase final)

cat("INTSINT annotation:\n")
tones_df <- tg_prosody$as_data_frame(tiers = "tones")
print(tones_df[, c("time", "label")])

# Example 3: Automatic Segmentation Editing (superassp use case)
cat("\nExample 3: Batch Annotation Editing\n")
cat("------------------------------------\n")

tg_batch <- TextGrid$create(0, 10, "auto manual")

# Simulate automatic segmentation
auto_boundaries <- seq(0.5, 9.5, by = 1.0)
for (boundary in auto_boundaries) {
  tg_batch$insert_boundary("auto", boundary)
}

# Label all intervals
n_intervals <- tg_batch$get_number_of_intervals("auto")
for (i in 1:n_intervals) {
  tg_batch$set_interval_text("auto", i, paste0("seg_", i))
}

# Duplicate to manual tier for correction
tg_batch$duplicate_tier("auto", "manual_duplicate")

# Show result
cat("Created", tg_batch$get_number_of_intervals("auto"), "automatic segments\n")

cat("\n==========================================================\n")
cat("TextGrid Editing Demonstration Complete!\n")
cat("==========================================================\n\n")

cat("Summary of Capabilities Demonstrated:\n")
cat("--------------------------------------\n")
cat("✓ Reading TextGrids from file\n")
cat("✓ Creating new TextGrids with interval and point tiers\n")
cat("✓ Inserting and removing boundaries\n")
cat("✓ Setting interval labels\n")
cat("✓ Inserting and removing points\n")
cat("✓ Setting point labels\n")
cat("✓ Adding new tiers (interval and point)\n")
cat("✓ Removing tiers\n")
cat("✓ Renaming tiers\n")
cat("✓ Duplicating tiers\n")
cat("✓ Extracting TextGrid segments\n")
cat("✓ Converting to data frames\n")
cat("✓ Saving TextGrids to file\n")
cat("✓ Practical workflows for:\n")
cat("    - VOT analysis (protoscribe)\n")
cat("    - MOMEL/INTSINT annotation (reindeer)\n")
cat("    - Batch annotation editing (superassp)\n")
cat("\nThese capabilities address the CRITICAL gaps identified in:\n")
cat("PRAAT_REPLICATION_GAP_ANALYSIS.md\n")
