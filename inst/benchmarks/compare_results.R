# Compare Benchmark Results
# Generates comparison report and visualizations
# 
# This script can compare:
# 1. SIMD baseline vs SIMD-optimized (primary use case)
# 2. speaker vs Parselmouth (when available)
# 3. speaker vs converted Praat scripts (when available)

library(ggplot2)

cat(strrep("=", 80), "\n")
cat("Benchmark Results Comparison\n")
cat(strrep("=", 80), "\n\n")

# Check if results exist
results_dir <- "inst/benchmarks/results"
if (!dir.exists(results_dir)) {
  stop("Results directory not found. Run 00_run_all_benchmarks.R first.")
}

# Load system info if available
sys_info_file <- file.path(results_dir, "00_system_info.rds")
completion_info_file <- file.path(results_dir, "00_completion_info.rds")

if (file.exists(sys_info_file) && file.exists(completion_info_file)) {
  sys_info <- readRDS(sys_info_file)
  completion_info <- readRDS(completion_info_file)
  
  cat("System Information\n")
  cat(strrep("=", 80), "\n")
  cat("Platform:", sys_info$platform, "\n")
  cat("R version:", sys_info$r_version, "\n")
  cat("CPU:", sys_info$cpu, "\n")
  cat("Package version:", as.character(completion_info$package_version), "\n")
  cat("Benchmark date:", format(completion_info$timestamp), "\n\n")
} else {
  cat("System information not found. Using default values.\n\n")
  sys_info <- list(platform = "unknown", r_version = "unknown", cpu = "unknown")
  completion_info <- list(package_version = "unknown", timestamp = Sys.time())
}

# ============================================================================
# SIMD Baseline vs Optimized Comparison (Primary Use Case)
# ============================================================================

# Benchmark files that may have baseline and simd versions
simd_benchmarks <- c(
  "01_matrix_operations",
  "02_data_conversion", 
  "03_tone_generation",
  "06_phase2_intensity",
  "07_phase2_sound_mixing",
  "08_phase3_fft_operations",
  "09_phase3_formant_lpc",
  "10_phase3_pitch_detection"
)

simd_comparisons_made <- FALSE

for (benchmark_name in simd_benchmarks) {
  baseline_file <- file.path(results_dir, paste0(benchmark_name, "_baseline.rds"))
  simd_file <- file.path(results_dir, paste0(benchmark_name, "_simd.rds"))
  
  if (file.exists(baseline_file) && file.exists(simd_file)) {
    if (!simd_comparisons_made) {
      cat(strrep("=", 80), "\n")
      cat("SIMD OPTIMIZATION RESULTS\n")
      cat(strrep("=", 80), "\n\n")
      simd_comparisons_made <- TRUE
    }
    
    baseline <- readRDS(baseline_file)
    simd <- readRDS(simd_file)
    
    cat("Benchmark:", benchmark_name, "\n")
    cat(strrep("-", 80), "\n")
    
    # Extract median times and compute speedup
    baseline_medians <- sapply(baseline$time, function(x) median(x))
    simd_medians <- sapply(simd$time, function(x) median(x))
    
    speedups <- baseline_medians / simd_medians
    
    # Create comparison data frame
    comparison_df <- data.frame(
      expression = as.character(baseline$expression),
      baseline_median = baseline_medians,
      simd_median = simd_medians,
      speedup = speedups
    )
    
    print(comparison_df)
    
    cat("\nSummary Statistics:\n")
    cat("  Mean speedup:   ", sprintf("%.2fx\n", mean(speedups)))
    cat("  Median speedup: ", sprintf("%.2fx\n", median(speedups)))
    cat("  Min speedup:    ", sprintf("%.2fx\n", min(speedups)))
    cat("  Max speedup:    ", sprintf("%.2fx\n", max(speedups)))
    
    # Assess SIMD effectiveness
    if (mean(speedups) >= 4.0) {
      cat("  ✅ Excellent SIMD optimization (4x+ speedup)\n")
    } else if (mean(speedups) >= 2.0) {
      cat("  ✅ Good SIMD optimization (2x+ speedup)\n")
    } else if (mean(speedups) >= 1.2) {
      cat("  ⚠️  Modest SIMD optimization (1.2x+ speedup)\n")
    } else if (mean(speedups) >= 0.9) {
      cat("  ⚠️  Minimal SIMD benefit (<1.2x speedup)\n")
    } else {
      cat("  ❌ SIMD regression (slower than baseline)\n")
    }
    cat("\n")
    
    # Create visualization
    plot_data <- comparison_df
    plot_data$expression <- factor(plot_data$expression, levels = plot_data$expression)
    
    p <- ggplot(plot_data, aes(x = expression, y = speedup)) +
      geom_col(fill = "steelblue") +
      geom_hline(yintercept = 1, linetype = "dashed", color = "red", linewidth = 1) +
      geom_hline(yintercept = 2, linetype = "dotted", color = "darkgreen", linewidth = 0.5) +
      geom_hline(yintercept = 4, linetype = "dotted", color = "darkgreen", linewidth = 0.5) +
      geom_text(aes(label = sprintf("%.2fx", speedup)), 
                vjust = -0.5, size = 3.5) +
      labs(
        title = paste("SIMD Optimization Results:", benchmark_name),
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
    
    plot_filename <- file.path(results_dir, paste0(benchmark_name, "_simd_comparison.png"))
    ggsave(plot_filename, p, width = 10, height = 6, dpi = 300)
    cat("Saved plot:", plot_filename, "\n\n")
  }
}

if (!simd_comparisons_made) {
  cat(strrep("=", 80), "\n")
  cat("SIMD OPTIMIZATION RESULTS\n")
  cat(strrep("=", 80), "\n\n")
  cat("No SIMD optimization results found yet.\n")
  cat("Baseline results available for:\n")
  for (benchmark_name in simd_benchmarks) {
    baseline_file <- file.path(results_dir, paste0(benchmark_name, "_baseline.rds"))
    if (file.exists(baseline_file)) {
      cat("  ✅", benchmark_name, "\n")
    }
  }
  cat("\nRun benchmarks again after SIMD implementation to generate comparisons.\n\n")
}

# ============================================================================
# Parselmouth Comparison (Optional)
# ============================================================================

pm_file <- file.path(results_dir, "04_parselmouth_comparison.rds")
if (file.exists(pm_file)) {
  cat(strrep("=", 80), "\n")
  cat("PARSELMOUTH COMPARISON\n")
  cat(strrep("=", 80), "\n\n")
  
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
# Converted Scripts Comparison (Optional)
# ============================================================================

scripts_file <- file.path(results_dir, "05_converted_scripts_comparison.rds")
if (file.exists(scripts_file)) {
  cat(strrep("=", 80), "\n")
  cat("CONVERTED SCRIPTS COMPARISON\n")
  cat(strrep("=", 80), "\n\n")
  
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

cat(strrep("=", 80), "\n")
cat("OVERALL SUMMARY\n")
cat(strrep("=", 80), "\n\n")

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
