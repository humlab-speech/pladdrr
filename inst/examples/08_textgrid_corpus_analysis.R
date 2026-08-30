# Example 8: Large-Scale TextGrid Corpus Analysis
# Demonstrates efficient processing of large annotated corpora
# Uses real benchmark data from inst/extdata/

library(speaker)

cat("================================================================================\n")
cat("Example 8: Large-Scale TextGrid Corpus Analysis\n")
cat("================================================================================\n\n")

cat("This example demonstrates:\n")
cat("  • Loading and processing large TextGrid files\n")
cat("  • Efficient extraction of annotation statistics\n")
cat("  • Tier-based analysis and filtering\n")
cat("  • Memory-efficient corpus processing\n")
cat("  • Performance benchmarking\n\n")

# ============================================================================
# Part 1: Load Benchmark TextGrid
# ============================================================================

cat("Part 1: Loading benchmark TextGrid data\n")
cat(strrep("=", 80), "\n\n")

# Use the 1-minute benchmark file (smaller than 10-min or 30-min versions)
tg_file <- system.file("extdata", "benchmarkdata1min.TextGrid", package = "speaker")

if (!file.exists(tg_file)) {
  cat("ERROR: Benchmark TextGrid file not found.\n")
  cat("Expected location:", tg_file, "\n")
  cat("Please ensure inst/extdata/benchmarkdata1min.TextGrid exists.\n\n")
  cat("Falling back to synthetic data demonstration...\n\n")
  
  # Create synthetic data for demonstration
  tg <- TextGrid$create(
    xmin = 0,
    xmax = 60,
    tier_names = c("utterances", "words", "phones"),
    point_tiers = c(FALSE, FALSE, FALSE)
  )
  
  # Add some sample annotations
  tg$insert_boundary(1, 10)
  tg$insert_boundary(1, 25)
  tg$insert_boundary(1, 45)
  
  tg$set_interval_label(1, 1, "silence")
  tg$set_interval_label(1, 2, "This is a test utterance")
  tg$set_interval_label(1, 3, "Another utterance here")
  tg$set_interval_label(1, 4, "silence")
  
  n_intervals_total <- tg$get_number_of_intervals(1)
  
} else {
  cat("Loading TextGrid file:", basename(tg_file), "\n")
  start_time <- Sys.time()
  
  tg <- TextGrid$new(tg_file)
  
  load_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  cat(sprintf("  ✓ Loaded in %.3f seconds\n", load_time))
  cat(sprintf("  Duration: %.2f seconds (%.2f minutes)\n", 
              tg$get_total_duration(), 
              tg$get_total_duration() / 60))
  cat(sprintf("  Number of tiers: %d\n", tg$get_number_of_tiers()))
  
  # Count total intervals/points
  n_intervals_total <- 0
  n_points_total <- 0
  for (i in 1:tg$get_number_of_tiers()) {
    if (tg$tier_is_interval_tier(i)) {
      n_intervals_total <- n_intervals_total + tg$get_number_of_intervals(i)
    } else {
      n_points_total <- n_points_total + tg$get_number_of_points(i)
    }
  }
  cat(sprintf("  Total intervals: %d\n", n_intervals_total))
  cat(sprintf("  Total points: %d\n", n_points_total))
  cat("\n")
}

# ============================================================================
# Part 2: Tier Structure Analysis
# ============================================================================

cat("\nPart 2: Analyzing tier structure\n")
cat(strrep("=", 80), "\n\n")

tier_names <- tg$get_tier_names()
n_tiers <- tg$get_number_of_tiers()

cat(sprintf("Found %d tiers:\n\n", n_tiers))
cat(sprintf("  %-5s %-30s %-15s %-10s\n", "Index", "Name", "Type", "Items"))
cat(sprintf("  %s\n", strrep("-", 65)))

tier_info <- list()

for (i in 1:n_tiers) {
  tier_name <- tier_names[i]
  is_interval <- tg$tier_is_interval_tier(i)
  tier_type <- if (is_interval) "IntervalTier" else "PointTier"
  
  n_items <- if (is_interval) {
    tg$get_number_of_intervals(i)
  } else {
    tg$get_number_of_points(i)
  }
  
  cat(sprintf("  %-5d %-30s %-15s %-10d\n", i, tier_name, tier_type, n_items))
  
  tier_info[[i]] <- list(
    index = i,
    name = tier_name,
    type = tier_type,
    n_items = n_items,
    is_interval = is_interval
  )
}

cat("\n")

# ============================================================================
# Part 3: Interval Duration Statistics
# ============================================================================

cat("\nPart 3: Computing interval duration statistics\n")
cat(strrep("=", 80), "\n\n")

# Analyze each interval tier
interval_tiers <- which(vapply(tier_info, function(x) x$is_interval, numeric(1)))

if (length(interval_tiers) > 0) {
  cat(sprintf("Analyzing %d interval tier(s):\n\n", length(interval_tiers)))
  
  for (tier_idx in interval_tiers) {
    tier_name <- tier_info[[tier_idx]]$name
    n_intervals <- tier_info[[tier_idx]]$n_items
    
    cat(sprintf("Tier '%s' (%d intervals):\n", tier_name, n_intervals))
    
    # Sample subset for large tiers (for efficiency)
    max_sample <- min(1000, n_intervals)
    sample_indices <- if (n_intervals > max_sample) {
      sort(sample(1:n_intervals, max_sample))
    } else {
      1:n_intervals
    }
    
    # Compute durations
    durations <- numeric(length(sample_indices))
    labels <- character(length(sample_indices))
    
    for (i in seq_along(sample_indices)) {
      interval_num <- sample_indices[i]
      start <- tg$get_interval_start_time(tier_idx, interval_num)
      end <- tg$get_interval_end_time(tier_idx, interval_num)
      durations[i] <- end - start
      labels[i] <- tg$get_interval_label(tier_idx, interval_num)
    }
    
    # Separate empty vs. labeled intervals
    non_empty <- nchar(trimws(labels)) > 0
    
    if (sum(non_empty) > 0) {
      labeled_durations <- durations[non_empty]
      cat(sprintf("  Labeled intervals: %d (%.1f%%)\n", 
                  sum(non_empty), 
                  100 * sum(non_empty) / length(non_empty)))
      cat(sprintf("  Mean duration: %.4f seconds\n", mean(labeled_durations)))
      cat(sprintf("  Median duration: %.4f seconds\n", median(labeled_durations)))
      cat(sprintf("  SD duration: %.4f seconds\n", sd(labeled_durations)))
      cat(sprintf("  Min duration: %.4f seconds\n", min(labeled_durations)))
      cat(sprintf("  Max duration: %.4f seconds\n", max(labeled_durations)))
      cat(sprintf("  Total coverage: %.2f seconds (%.1f%%)\n", 
                  sum(labeled_durations),
                  100 * sum(labeled_durations) / tg$get_total_duration()))
    } else {
      cat("  No labeled intervals found\n")
    }
    
    # Show most common labels
    if (sum(non_empty) > 0) {
      label_counts <- table(labels[non_empty])
      top_labels <- head(sort(label_counts, decreasing = TRUE), 10)
      
      if (length(top_labels) > 0) {
        cat("\n  Top 10 most frequent labels:\n")
        for (j in seq_len(min(10, length(top_labels)))) {
          label_name <- names(top_labels)[j]
          count <- top_labels[j]
          pct <- 100 * count / sum(non_empty)
          cat(sprintf("    %-20s: %5d (%.1f%%)\n", label_name, count, pct))
        }
      }
    }
    
    cat("\n")
  }
} else {
  cat("No interval tiers found in this TextGrid.\n\n")
}

# ============================================================================
# Part 4: Label Distribution Analysis
# ============================================================================

cat("\nPart 4: Label distribution and pattern analysis\n")
cat(strrep("=", 80), "\n\n")

if (length(interval_tiers) > 0) {
  # Pick the first interval tier for detailed analysis
  tier_idx <- interval_tiers[1]
  tier_name <- tier_info[[tier_idx]]$name
  n_intervals <- tier_info[[tier_idx]]$n_items
  
  cat(sprintf("Analyzing tier: '%s'\n\n", tier_name))
  
  # Extract all labels (sample if too large)
  max_labels <- min(5000, n_intervals)
  sample_indices <- if (n_intervals > max_labels) {
    sort(sample(1:n_intervals, max_labels))
  } else {
    1:n_intervals
  }
  
  cat(sprintf("Analyzing %d intervals (sampled from %d)...\n", 
              length(sample_indices), n_intervals))
  
  all_labels <- character(length(sample_indices))
  for (i in seq_along(sample_indices)) {
    all_labels[i] <- tg$get_interval_label(tier_idx, sample_indices[i])
  }
  
  # Statistics
  empty_count <- sum(nchar(trimws(all_labels)) == 0)
  unique_count <- length(unique(all_labels[nchar(trimws(all_labels)) > 0]))
  
  cat(sprintf("  Empty labels: %d (%.1f%%)\n", empty_count, 
              100 * empty_count / length(all_labels)))
  cat(sprintf("  Unique non-empty labels: %d\n", unique_count))
  
  # Character length distribution
  non_empty_labels <- all_labels[nchar(trimws(all_labels)) > 0]
  if (length(non_empty_labels) > 0) {
    label_lengths <- nchar(non_empty_labels)
    cat(sprintf("  Average label length: %.1f characters\n", mean(label_lengths)))
    cat(sprintf("  Label length range: %d - %d characters\n", 
                min(label_lengths), max(label_lengths)))
  }
  
  cat("\n")
}

# ============================================================================
# Part 5: Temporal Coverage Analysis
# ============================================================================

cat("\nPart 5: Temporal coverage analysis\n")
cat(strrep("=", 80), "\n\n")

if (length(interval_tiers) > 0) {
  total_duration <- tg$get_total_duration()
  
  cat("Calculating temporal coverage for each tier:\n\n")
  cat(sprintf("  %-30s %-15s %-15s %-10s\n", "Tier", "Labeled (s)", "Coverage (%)", "Intervals"))
  cat(sprintf("  %s\n", strrep("-", 75)))
  
  for (tier_idx in interval_tiers) {
    tier_name <- tier_info[[tier_idx]]$name
    n_intervals <- tier_info[[tier_idx]]$n_items
    
    # Sample for efficiency
    max_sample <- min(1000, n_intervals)
    sample_indices <- if (n_intervals > max_sample) {
      sample(1:n_intervals, max_sample)
    } else {
      1:n_intervals
    }
    
    labeled_time <- 0
    labeled_count <- 0
    
    for (i in sample_indices) {
      label <- tg$get_interval_label(tier_idx, i)
      if (nchar(trimws(label)) > 0) {
        start <- tg$get_interval_start_time(tier_idx, i)
        end <- tg$get_interval_end_time(tier_idx, i)
        labeled_time <- labeled_time + (end - start)
        labeled_count <- labeled_count + 1
      }
    }
    
    # Scale up if we sampled
    if (n_intervals > max_sample) {
      scale_factor <- n_intervals / max_sample
      labeled_time <- labeled_time * scale_factor
      labeled_count <- round(labeled_count * scale_factor)
    }
    
    coverage_pct <- 100 * labeled_time / total_duration
    
    cat(sprintf("  %-30s %-15.2f %-15.1f %-10d\n", 
                tier_name, labeled_time, coverage_pct, labeled_count))
  }
  
  cat("\n")
}

# ============================================================================
# Part 6: Data Export
# ============================================================================

cat("\nPart 6: Exporting data for downstream analysis\n")
cat(strrep("=", 80), "\n\n")

# Export full TextGrid as data frame
cat("Converting TextGrid to data frame...\n")
start_time <- Sys.time()

# For large TextGrids, this might take time - sample if needed
if (n_intervals_total > 10000) {
  cat(sprintf("  WARNING: Large TextGrid (%d intervals)\n", n_intervals_total))
  cat("  Consider exporting specific tiers or time ranges\n")
  cat("  Sampling first tier only for demonstration...\n\n")
  
  # Export only first tier
  tg_df <- tg$as_data_frame(tiers = 1)
} else {
  tg_df <- tg$as_data_frame()
}

export_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))

cat(sprintf("  ✓ Exported in %.3f seconds\n", export_time))
cat(sprintf("  Dimensions: %d rows × %d columns\n", nrow(tg_df), ncol(tg_df)))
cat(sprintf("  Columns: %s\n", toString(names(tg_df))))
cat("\n")

# Show sample
cat("Sample of exported data:\n")
print(head(tg_df, 10))
cat("\n")

# Save to file
output_file <- file.path(tempdir(), "textgrid_export.csv")
write.csv(tg_df, output_file, row.names = FALSE)
cat("Exported data saved to:", output_file, "\n")
cat("File size:", round(file.size(output_file) / 1024, 1), "KB\n\n")

# ============================================================================
# Part 7: Performance Benchmarking
# ============================================================================

cat("\nPart 7: Performance benchmarking\n")
cat(strrep("=", 80), "\n\n")

if (length(interval_tiers) > 0) {
  tier_idx <- interval_tiers[1]
  n_intervals <- tier_info[[tier_idx]]$n_items
  
  cat("Benchmarking TextGrid query operations:\n\n")
  
  # Benchmark: Sequential label retrieval
  n_queries <- min(1000, n_intervals)
  query_indices <- sample(1:n_intervals, n_queries)
  
  start_time <- Sys.time()
  for (i in query_indices) {
    label <- tg$get_interval_label(tier_idx, i)
  }
  query_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  cat(sprintf("  Sequential label queries: %d queries in %.3f s\n", 
              n_queries, query_time))
  cat(sprintf("  Average time per query: %.4f ms\n", 
              1000 * query_time / n_queries))
  
  # Benchmark: Time-based queries
  n_time_queries <- 100
  query_times <- seq(tg$get_start_time(), tg$get_end_time(), 
                     length.out = n_time_queries)
  
  start_time <- Sys.time()
  for (t in query_times) {
    label <- tg$get_label_at_time(tier_idx, t)
  }
  time_query_time <- as.numeric(difftime(Sys.time(), start_time, units = "secs"))
  
  cat(sprintf("  Time-based label queries: %d queries in %.3f s\n", 
              n_time_queries, time_query_time))
  cat(sprintf("  Average time per query: %.4f ms\n", 
              1000 * time_query_time / n_time_queries))
  
  cat("\n")
}

# ============================================================================
# Summary
# ============================================================================

cat("\n")
cat(strrep("=", 80), "\n")
cat("Example 8 Complete!\n")
cat(strrep("=", 80), "\n\n")

cat("This example demonstrated:\n\n")

cat("✓ LARGE-SCALE DATA HANDLING\n")
cat("  • Loading benchmark TextGrid files\n")
cat("  • Efficient sampling strategies for large corpora\n")
cat("  • Memory-conscious processing\n\n")

cat("✓ STATISTICAL ANALYSIS\n")
cat("  • Duration statistics (mean, median, SD)\n")
cat("  • Label frequency distributions\n")
cat("  • Temporal coverage calculations\n\n")

cat("✓ DATA EXPORT\n")
cat("  • Conversion to R data frames\n")
cat("  • CSV export for external analysis\n")
cat("  • Selective tier export\n\n")

cat("✓ PERFORMANCE\n")
cat("  • Benchmarking query operations\n")
cat("  • Timing comparisons\n")
cat("  • Scalability assessment\n\n")

cat("PRACTICAL APPLICATIONS:\n")
cat("  • Corpus-wide annotation statistics\n")
cat("  • Quality control for manual annotations\n")
cat("  • Preprocessing for machine learning pipelines\n")
cat("  • Batch feature extraction from large corpora\n\n")

cat("For related examples, see:\n")
cat("  • inst/examples/06_textgrid_analysis.R - Basic TextGrid operations\n")
cat("  • inst/examples/07_comprehensive_phonetic_analysis.R - Integrated analysis\n\n")
