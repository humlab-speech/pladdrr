# Compare Benchmark Results
# Generates comparison report and visualizations

library(ggplot2)

cat("========================================\n")
cat("Benchmark Results Comparison\n")
cat("========================================\n\n")

# Check if results exist
results_dir <- "inst/benchmarks/results"
if (!dir.exists(results_dir)) {
  stop("Results directory not found. Run 00_run_all_benchmarks.R first.")
}

# Load system info
sys_info <- readRDS(file.path(results_dir, "00_system_info.rds"))
completion_info <- readRDS(file.path(results_dir, "00_completion_info.rds"))

cat("System Information\n")
cat("==================\n")
cat("Platform:", sys_info$platform, "\n")
cat("R version:", sys_info$r_version, "\n")
cat("CPU:", sys_info$cpu, "\n")
cat("Package version:", as.character(completion_info$package_version), "\n")
cat("Benchmark date:", format(completion_info$timestamp), "\n\n")

# ============================================================================
# Parselmouth Comparison
# ============================================================================

pm_file <- file.path(results_dir, "04_parselmouth_comparison.rds")
if (file.exists(pm_file)) {
  cat("Parselmouth Comparison\n")
  cat("======================\n")
  
  pm_results <- readRDS(pm_file)
  
  print(pm_results$summary)
  cat("\n")
  
  # Calculate summary statistics
  mean_speedup <- mean(pm_results$summary$speedup)
  median_speedup <- median(pm_results$summary$speedup)
  min_speedup <- min(pm_results$summary$speedup)
  max_speedup <- max(pm_results$summary$speedup)
  
  cat("Summary Statistics:\n")
  cat("  Mean speedup:   ", sprintf("%.2fx\n", mean_speedup))
  cat("  Median speedup: ", sprintf("%.2fx\n", median_speedup))
  cat("  Min speedup:    ", sprintf("%.2fx\n", min_speedup))
  cat("  Max speedup:    ", sprintf("%.2fx\n", max_speedup))
  cat("\n")
  
  # Create visualization
  p1 <- ggplot(pm_results$summary, aes(x = operation, y = speedup)) +
    geom_col(fill = "steelblue") +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    geom_text(aes(label = sprintf("%.2fx", speedup)), 
              vjust = -0.5, size = 3.5) +
    labs(
      title = "speaker vs Parselmouth Performance",
      subtitle = paste0("Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu),
      x = "Operation",
      y = "Speedup (times faster)",
      caption = paste0("Package version: ", completion_info$package_version, 
                      " | Benchmark date: ", format(completion_info$timestamp))
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  ggsave("inst/benchmarks/results/parselmouth_comparison.png", 
         p1, width = 8, height = 6, dpi = 300)
  cat("Saved plot: inst/benchmarks/results/parselmouth_comparison.png\n\n")
  
} else {
  cat("Parselmouth comparison results not found. Skipping.\n\n")
}

# ============================================================================
# Converted Scripts Comparison
# ============================================================================

scripts_file <- file.path(results_dir, "05_converted_scripts_comparison.rds")
if (file.exists(scripts_file)) {
  cat("Converted Scripts Comparison\n")
  cat("============================\n")
  
  scripts_results <- readRDS(scripts_file)
  
  print(scripts_results$summary)
  cat("\n")
  
  # Calculate summary statistics
  mean_speedup <- mean(scripts_results$summary$speedup)
  median_speedup <- median(scripts_results$summary$speedup)
  min_speedup <- min(scripts_results$summary$speedup)
  max_speedup <- max(scripts_results$summary$speedup)
  
  cat("Summary Statistics:\n")
  cat("  Mean speedup:   ", sprintf("%.2fx\n", mean_speedup))
  cat("  Median speedup: ", sprintf("%.2fx\n", median_speedup))
  cat("  Min speedup:    ", sprintf("%.2fx\n", min_speedup))
  cat("  Max speedup:    ", sprintf("%.2fx\n", max_speedup))
  cat("\n")
  
  # Create visualization
  p2 <- ggplot(scripts_results$summary, aes(x = workflow, y = speedup)) +
    geom_col(fill = "darkgreen") +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    geom_text(aes(label = sprintf("%.2fx", speedup)), 
              vjust = -0.5, size = 3.5) +
    labs(
      title = "speaker vs Parselmouth: Full Workflow Performance",
      subtitle = paste0("Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu),
      x = "Workflow",
      y = "Speedup (times faster)",
      caption = paste0("Package version: ", completion_info$package_version, 
                      " | Benchmark date: ", format(completion_info$timestamp))
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )
  
  ggsave("inst/benchmarks/results/converted_scripts_comparison.png", 
         p2, width = 8, height = 6, dpi = 300)
  cat("Saved plot: inst/benchmarks/results/converted_scripts_comparison.png\n\n")
  
} else {
  cat("Converted scripts comparison results not found. Skipping.\n\n")
}

# ============================================================================
# Combined Summary
# ============================================================================

cat("========================================\n")
cat("Overall Summary\n")
cat("========================================\n\n")

if (file.exists(pm_file) && file.exists(scripts_file)) {
  pm_results <- readRDS(pm_file)
  scripts_results <- readRDS(scripts_file)
  
  all_speedups <- c(pm_results$summary$speedup, scripts_results$summary$speedup)
  
  cat("Combined Performance Metrics:\n")
  cat("  Overall mean speedup:   ", sprintf("%.2fx\n", mean(all_speedups)))
  cat("  Overall median speedup: ", sprintf("%.2fx\n", median(all_speedups)))
  cat("  Overall min speedup:    ", sprintf("%.2fx\n", min(all_speedups)))
  cat("  Overall max speedup:    ", sprintf("%.2fx\n", max(all_speedups)))
  cat("\n")
  
  # Combined data frame
  combined_df <- rbind(
    data.frame(
      category = "Individual Operations",
      test = pm_results$summary$operation,
      speedup = pm_results$summary$speedup
    ),
    data.frame(
      category = "Full Workflows",
      test = scripts_results$summary$workflow,
      speedup = scripts_results$summary$speedup
    )
  )
  
  # Combined visualization
  p3 <- ggplot(combined_df, aes(x = test, y = speedup, fill = category)) +
    geom_col() +
    geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
    geom_text(aes(label = sprintf("%.2fx", speedup)), 
              vjust = -0.5, size = 3) +
    scale_fill_manual(values = c("Individual Operations" = "steelblue", 
                                  "Full Workflows" = "darkgreen")) +
    labs(
      title = "speaker vs Parselmouth: Complete Performance Comparison",
      subtitle = paste0("Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu),
      x = "Test",
      y = "Speedup (times faster)",
      fill = "Category",
      caption = paste0("Package version: ", completion_info$package_version, 
                      " | Benchmark date: ", format(completion_info$timestamp))
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )
  
  ggsave("inst/benchmarks/results/combined_comparison.png", 
         p3, width = 10, height = 6, dpi = 300)
  cat("Saved plot: inst/benchmarks/results/combined_comparison.png\n\n")
  
  cat("Interpretation:\n")
  cat("  Values > 1.0: speaker is faster\n")
  cat("  Values < 1.0: Parselmouth is faster\n")
  cat("  Values = 1.0: Equal performance\n\n")
  
  cat("Key Findings:\n")
  if (mean(all_speedups) > 1.5) {
    cat("  ✅ speaker shows significant performance advantage (>1.5x on average)\n")
  } else if (mean(all_speedups) > 1.0) {
    cat("  ✅ speaker shows moderate performance advantage (>1.0x on average)\n")
  } else {
    cat("  ⚠️  Performance is comparable to Parselmouth\n")
  }
  
  if (min(all_speedups) < 1.0) {
    cat("  ⚠️  Some operations are slower than Parselmouth\n")
  }
  
  cat("\n")
  
} else {
  cat("Not all benchmark results available for combined summary.\n\n")
}

cat("Comparison complete!\n")
cat("Check inst/benchmarks/results/ for plots and detailed results.\n")
