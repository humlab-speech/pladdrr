# Example 6: TextGrid Analysis and Manipulation
# Demonstrates comprehensive TextGrid functionality with real data

library(speaker)

cat("================================================================================\n")
cat("Example 6: TextGrid Analysis and Manipulation\n")
cat("================================================================================\n\n")

# 1. Load TextGrid file
cat("1. Loading TextGrid from file...\n")
tg_file <- system.file("extdata", "benchmarkdata1min.TextGrid", package = "speaker")
if (!file.exists(tg_file)) {
  stop("TextGrid file not found. Please ensure inst/extdata/benchmarkdata1min.TextGrid exists.")
}

tg <- TextGrid$new(tg_file)
cat("   ✓ Loaded TextGrid\n")
cat("   Duration:", tg$get_total_duration(), "seconds\n")
cat("   Number of tiers:", tg$get_number_of_tiers(), "\n\n")

# 2. Explore tier structure
cat("2. Exploring tier structure...\n")
for (i in 1:tg$get_number_of_tiers()) {
  tier_name <- tg$get_tier_name(i)
  tier_class <- if (tg$is_interval_tier(i)) "IntervalTier" else "PointTier"
  
  if (tg$is_interval_tier(i)) {
    n_items <- tg$get_number_of_intervals(i)
    cat(sprintf("   Tier %d: %s (%s) - %d intervals\n", 
                i, tier_name, tier_class, n_items))
  } else {
    n_items <- tg$get_number_of_points(i)
    cat(sprintf("   Tier %d: %s (%s) - %d points\n", 
                i, tier_name, tier_class, n_items))
  }
}
cat("\n")

# 3. Extract and analyze first interval tier
cat("3. Analyzing interval tier...\n")
tier_idx <- 1
tier_name <- tg$get_tier_name(tier_idx)
cat("   Analyzing tier:", tier_name, "\n")

n_intervals <- tg$get_number_of_intervals(tier_idx)
cat("   Total intervals:", n_intervals, "\n")

# Sample first 10 intervals
cat("\n   First 10 intervals:\n")
cat("   ", sprintf("%-6s %-10s %-10s %-20s\n", "Index", "Start", "End", "Label"))
cat("   ", strrep("-", 50), "\n")

for (i in seq_len(min(10, n_intervals))) {
  start_time <- tg$get_interval_start_time(tier_idx, i)
  end_time <- tg$get_interval_end_time(tier_idx, i)
  label <- tg$get_interval_label(tier_idx, i)
  
  cat("   ", sprintf("%-6d %-10.3f %-10.3f %-20s\n", 
                     i, start_time, end_time, label))
}
cat("\n")

# 4. Query intervals by time
cat("4. Querying intervals by time...\n")
query_time <- tg$get_total_duration() / 2  # Middle of the TextGrid
interval_idx <- tg$get_interval_at_time(tier_idx, query_time)
if (!is.na(interval_idx)) {
  label <- tg$get_interval_label(tier_idx, interval_idx)
  start_time <- tg$get_interval_start_time(tier_idx, interval_idx)
  end_time <- tg$get_interval_end_time(tier_idx, interval_idx)
  cat(sprintf("   At time %.3f seconds:\n", query_time))
  cat(sprintf("   Interval %d: [%.3f - %.3f] '%s'\n", 
              interval_idx, start_time, end_time, label))
} else {
  cat("   No interval found at time", query_time, "\n")
}
cat("\n")

# 5. Count labels
cat("5. Analyzing label distribution...\n")
labels <- character()
for (i in 1:n_intervals) {
  labels <- c(labels, tg$get_interval_label(tier_idx, i))
}

label_counts <- table(labels)
cat("   Label distribution (top 10):\n")
top_labels <- head(sort(label_counts, decreasing = TRUE), 10)
for (i in seq_along(top_labels)) {
  cat(sprintf("   %-20s: %d occurrences\n", 
              names(top_labels)[i], top_labels[i]))
}
cat("\n")

# 6. Extract intervals matching a pattern
cat("6. Finding intervals matching pattern...\n")
pattern <- "^[aeiou]$"  # Single vowels (if phonetic annotation)
matching_intervals <- list()

for (i in 1:n_intervals) {
  label <- tg$get_interval_label(tier_idx, i)
  if (grepl(pattern, label, ignore.case = TRUE)) {
    matching_intervals[[length(matching_intervals) + 1]] <- list(
      index = i,
      label = label,
      start = tg$get_interval_start_time(tier_idx, i),
      end = tg$get_interval_end_time(tier_idx, i)
    )
  }
}

if (length(matching_intervals) > 0) {
  cat(sprintf("   Found %d intervals matching pattern '%s'\n", 
              length(matching_intervals), pattern))
  cat("\n   Sample matches (first 5):\n")
  for (i in seq_len(min(5, length(matching_intervals)))) {
    item <- matching_intervals[[i]]
    cat(sprintf("   [%.3f - %.3f]: %s\n", 
                item$start, item$end, item$label))
  }
} else {
  cat("   No intervals found matching pattern '", pattern, "'\n", sep = "")
}
cat("\n")

# 7. Calculate interval statistics
cat("7. Interval duration statistics...\n")
durations <- numeric(n_intervals)
for (i in 1:n_intervals) {
  start_time <- tg$get_interval_start_time(tier_idx, i)
  end_time <- tg$get_interval_end_time(tier_idx, i)
  durations[i] <- end_time - start_time
}

non_empty_labels <- sapply(1:n_intervals, function(i) {
  nchar(trimws(tg$get_interval_label(tier_idx, i))) > 0
})

if (sum(non_empty_labels) > 0) {
  labeled_durations <- durations[non_empty_labels]
  cat(sprintf("   Mean duration: %.3f seconds\n", mean(labeled_durations)))
  cat(sprintf("   Median duration: %.3f seconds\n", median(labeled_durations)))
  cat(sprintf("   Min duration: %.3f seconds\n", min(labeled_durations)))
  cat(sprintf("   Max duration: %.3f seconds\n", max(labeled_durations)))
  cat(sprintf("   Total labeled time: %.3f seconds\n", sum(labeled_durations)))
  cat(sprintf("   Percentage labeled: %.1f%%\n", 
              100 * sum(labeled_durations) / tg$get_total_duration()))
} else {
  cat("   No labeled intervals found\n")
}
cat("\n")

# 8. Export to data frame
cat("8. Exporting to R data frame...\n")
df <- tg$as_data_frame()
cat("   ✓ Exported to data frame\n")
cat("   Dimensions:", nrow(df), "rows ×", ncol(df), "columns\n")
cat("   Column names:", toString(names(df)), "\n")
cat("\n   Preview (first 10 rows):\n")
print(head(df, 10))
cat("\n")

# 9. Demonstrate modification (if supported)
cat("9. TextGrid modification example...\n")
cat("   Creating a copy for demonstration...\n")

# Create a new simple TextGrid for modification demo
tg_new <- TextGrid$create(xmin = 0, xmax = 5, tier_names = "demo", point_tiers = FALSE)
cat("   ✓ Created new TextGrid (0-5 seconds)\n")
cat("   Duration:", tg_new$get_total_duration(), "seconds\n")
cat("   Tiers:", tg_new$get_number_of_tiers(), "\n")

# Add intervals
cat("\n   Adding intervals...\n")
tg_new$insert_boundary(tier_number = 1, time = 1.0)
tg_new$insert_boundary(tier_number = 1, time = 2.5)
tg_new$insert_boundary(tier_number = 1, time = 4.0)
cat("   ✓ Added 3 boundaries\n")

# Set labels
tg_new$set_interval_label(tier_number = 1, interval_number = 1, label = "silence")
tg_new$set_interval_label(tier_number = 1, interval_number = 2, label = "speech")
tg_new$set_interval_label(tier_number = 1, interval_number = 3, label = "pause")
tg_new$set_interval_label(tier_number = 1, interval_number = 4, label = "speech")
cat("   ✓ Set interval labels\n")

cat("\n   Modified TextGrid structure:\n")
for (i in 1:tg_new$get_number_of_intervals(1)) {
  start <- tg_new$get_interval_start_time(1, i)
  end <- tg_new$get_interval_end_time(1, i)
  label <- tg_new$get_interval_label(1, i)
  cat(sprintf("   Interval %d: [%.2f - %.2f] '%s'\n", i, start, end, label))
}
cat("\n")

# 10. Save modified TextGrid
output_file <- file.path(tempdir(), "demo_textgrid.TextGrid")
tg_new$save(output_file)
cat("10. Saving modified TextGrid...\n")
cat("   ✓ Saved to:", output_file, "\n")
cat("   File size:", file.size(output_file), "bytes\n\n")

# Verify we can reload it
tg_reloaded <- TextGrid$new(output_file)
cat("   ✓ Successfully reloaded TextGrid\n")
cat("   Verified intervals:", tg_reloaded$get_number_of_intervals(1), "\n")

cat("\n")
cat("================================================================================\n")
cat("Example 6 Complete!\n")
cat("================================================================================\n")
cat("\nKey capabilities demonstrated:\n")
cat("  ✓ Load TextGrid files\n")
cat("  ✓ Query tier structure and properties\n")
cat("  ✓ Extract interval/point information\n")
cat("  ✓ Query by time\n")
cat("  ✓ Analyze label distributions\n")
cat("  ✓ Calculate duration statistics\n")
cat("  ✓ Export to R data frames\n")
cat("  ✓ Create and modify TextGrids\n")
cat("  ✓ Save TextGrids to files\n")
cat("\nThis example shows how speaker provides comprehensive TextGrid support\n")
cat("for annotation, analysis, and manipulation workflows.\n")
