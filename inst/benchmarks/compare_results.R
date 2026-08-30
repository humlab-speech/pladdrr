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

if (file.exists(sys_info_file)) {
  sys_info <- readRDS(sys_info_file)

  cat("System Information\n")
  cat(strrep("=", 80), "\n")
  cat("Platform:", sys_info$platform, "\n")
  cat("R version:", sys_info$r_version, "\n")
  cat(
    "CPU:",
    if (!is.null(sys_info$cpu_info)) sys_info$cpu_info else "Unknown",
    "\n"
  )
  cat("Package version:", sys_info$package_version, "\n")
  cat(
    "Benchmark date:",
    format(sys_info$timestamp, "%Y-%m-%d %H:%M:%S"),
    "\n\n"
  )
} else {
  cat("System information not found. Using default values.\n\n")
  sys_info <- list(
    platform = R.version$platform,
    r_version = R.version.string,
    cpu_info = "Unknown",
    package_version = as.character(packageVersion("speaker")),
    timestamp = Sys.time()
  )
}

# ============================================================================
# SIMD Baseline vs Optimized Comparison (Primary Use Case)
# ============================================================================

# Benchmark files that may have scalar and simd versions
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
  scalar_file <- file.path(results_dir, paste0(benchmark_name, "_scalar.rds"))
  simd_file <- file.path(results_dir, paste0(benchmark_name, "_simd.rds"))
  baseline_file <- file.path(
    results_dir, paste0(benchmark_name, "_baseline.rds")
  )

  # Support both scalar/simd and baseline naming
  if (!file.exists(scalar_file) && file.exists(baseline_file)) {
    scalar_file <- baseline_file
  }

  if (file.exists(scalar_file) && file.exists(simd_file)) {
    if (!simd_comparisons_made) {
      cat(strrep("=", 80), "\n")
      cat("SIMD OPTIMIZATION RESULTS\n")
      cat(strrep("=", 80), "\n\n")
      simd_comparisons_made <- TRUE
    }

    scalar <- readRDS(scalar_file)
    simd <- readRDS(simd_file)

    cat("Benchmark:", benchmark_name, "\n")
    cat(strrep("-", 80), "\n")

    # Handle both list and bench_mark formats
    if (is.list(scalar) && !inherits(scalar, "bench_mark")) {
      # Nested list format - extract all test configurations
      all_speedups <- NULL

      for (size_name in names(scalar)) {
        if (!size_name %in% names(simd)) next

        scalar_config <- scalar[[size_name]]
        simd_config <- simd[[size_name]]

        # Handle nested structure (e.g., create/export sub-benchmarks)
        if (is.list(scalar_config) && !inherits(scalar_config, "bench_mark")) {
          for (sub_name in names(scalar_config)) {
            if (inherits(scalar_config[[sub_name]], "bench_mark") &&
                  sub_name %in% names(simd_config)) {
              scalar_bench <- scalar_config[[sub_name]]
              simd_bench <- simd_config[[sub_name]]

              if (nrow(scalar_bench) > 0 && nrow(simd_bench) > 0) {
                scalar_medians <- as.numeric(scalar_bench$median)
                simd_medians <- as.numeric(simd_bench$median)
                speedups_sub <- scalar_medians / simd_medians
                all_speedups <- c(all_speedups, speedups_sub)

                cat(sprintf("\nConfiguration: %s - %s\n", size_name, sub_name))
                comparison_df <- data.frame(
                  expression = as.character(scalar_bench$expression),
                  scalar_ms = scalar_medians * 1000,
                  simd_ms = simd_medians * 1000,
                  speedup = speedups_sub
                )
                print(comparison_df)
              }
            }
          }
        } else {
          # Direct bench_mark at this level
          scalar_bench <- scalar_config
          simd_bench <- simd_config

          if (inherits(scalar_bench, "bench_mark") && nrow(scalar_bench) > 0) {
            scalar_medians <- as.numeric(scalar_bench$median)
            simd_medians <- as.numeric(simd_bench$median)
            speedups_sub <- scalar_medians / simd_medians
            all_speedups <- c(all_speedups, speedups_sub)

            cat(sprintf("\nConfiguration: %s\n", size_name))
            comparison_df <- data.frame(
              expression = as.character(scalar_bench$expression),
              scalar_ms = scalar_medians * 1000,
              simd_ms = simd_medians * 1000,
              speedup = speedups_sub
            )
            print(comparison_df)
          }
        }
      }

      # Use all speedups for summary
      speedups <- all_speedups
    } else {
      # Direct bench_mark format
      scalar_medians <- as.numeric(scalar$median)
      simd_medians <- as.numeric(simd$median)

      speedups <- scalar_medians / simd_medians

      # Create comparison data frame
      comparison_df <- data.frame(
        expression = as.character(scalar$expression),
        scalar_ms = scalar_medians * 1000,
        simd_ms = simd_medians * 1000,
        speedup = speedups
      )

      print(comparison_df)
    }

    if (length(speedups) == 0) {
      cat("⚠️  No valid benchmark data found\n\n")
      next
    }

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
    plot_data$expression <- factor(
      plot_data$expression,
      levels = plot_data$expression
    )

    p <- ggplot(plot_data, aes(x = expression, y = speedup)) +
      geom_col(fill = "steelblue") +
      geom_hline(
        yintercept = 1, linetype = "dashed", color = "red", linewidth = 1
      ) +
      geom_hline(
        yintercept = 2, linetype = "dotted", color = "darkgreen",
        linewidth = 0.5
      ) +
      geom_hline(
        yintercept = 4, linetype = "dotted", color = "darkgreen",
        linewidth = 0.5
      ) +
      geom_text(aes(label = sprintf("%.2fx", speedup)),
        vjust = -0.5, size = 3.5
      ) +
      labs(
        title = paste("SIMD Optimization Results:", benchmark_name),
        subtitle = paste0(
          "Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu_info
        ),
        x = "Operation",
        y = "Speedup (times faster)",
        caption = paste0(
          "Package version: ", sys_info$package_version,
          " | Benchmark date: ", format(sys_info$timestamp, "%Y-%m-%d")
        )
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 9),
        axis.text.x = element_text(angle = 45, hjust = 1)
      )

    plot_filename <- file.path(
      results_dir, paste0(benchmark_name, "_simd_comparison.png")
    )
    ggsave(plot_filename, p, width = 10, height = 6, dpi = 300)
    cat("Saved plot:", plot_filename, "\n\n")
  }
}

if (!simd_comparisons_made) {
  cat(strrep("=", 80), "\n")
  cat("SIMD OPTIMIZATION RESULTS\n")
  cat(strrep("=", 80), "\n\n")
  cat("No SIMD optimization results found yet.\n")

  # Check what modes are available
  scalar_available <- NULL
  simd_available <- NULL
  baseline_available <- NULL

  for (benchmark_name in simd_benchmarks) {
    scalar_file <- file.path(
      results_dir, paste0(benchmark_name, "_scalar.rds")
    )
    simd_file <- file.path(results_dir, paste0(benchmark_name, "_simd.rds"))
    baseline_file <- file.path(
      results_dir, paste0(benchmark_name, "_baseline.rds")
    )

    if (file.exists(scalar_file)) {
      scalar_available <- c(scalar_available, benchmark_name)
    }
    if (file.exists(simd_file)) {
      simd_available <- c(simd_available, benchmark_name)
    }
    if (file.exists(baseline_file)) {
      baseline_available <- c(baseline_available, benchmark_name)
    }
  }

  if (length(scalar_available) > 0 || length(baseline_available) > 0) {
    cat("Scalar/baseline results available for:\n")
    for (bn in union(scalar_available, baseline_available)) {
      cat("  ✅", bn, "\n")
    }
  }

  if (length(simd_available) > 0) {
    cat("\nSIMD results available for:\n")
    for (bn in simd_available) {
      cat("  ✅", bn, "\n")
    }
  }

  if (length(scalar_available) > 0 && length(simd_available) == 0) {
    cat(
      "\nRun benchmarks with RcppXsimd installed to generate SIMD ",
      "comparisons.\n",
      sep = ""
    )
  } else if (length(scalar_available) == 0 && length(simd_available) > 0) {
    cat("\nRun benchmarks without RcppXsimd to generate scalar baseline.\n")
  }

  cat("\n")
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

  # Calculate summary statistics for parselmouth comparison
  mean_speedup_pm <- mean(
    pm_results$summary$speedup_vs_parselmouth, na.rm = TRUE
  )
  median_speedup_pm <- median(
    pm_results$summary$speedup_vs_parselmouth, na.rm = TRUE
  )
  min_speedup_pm <- min(pm_results$summary$speedup_vs_parselmouth, na.rm = TRUE)
  max_speedup_pm <- max(pm_results$summary$speedup_vs_parselmouth, na.rm = TRUE)

  cat("Summary Statistics (vs Parselmouth):\n")
  cat("  Mean speedup:   ", sprintf("%.2fx\n", mean_speedup_pm))
  cat("  Median speedup: ", sprintf("%.2fx\n", median_speedup_pm))
  cat("  Min speedup:    ", sprintf("%.2fx\n", min_speedup_pm))
  cat("  Max speedup:    ", sprintf("%.2fx\n", max_speedup_pm))

  # Calculate summary statistics for Praat comparison (if available)
  if (!all(is.na(pm_results$summary$speedup_vs_praat))) {
    mean_speedup_praat <- mean(
      pm_results$summary$speedup_vs_praat, na.rm = TRUE
    )
    median_speedup_praat <- median(
      pm_results$summary$speedup_vs_praat, na.rm = TRUE
    )
    min_speedup_praat <- min(pm_results$summary$speedup_vs_praat, na.rm = TRUE)
    max_speedup_praat <- max(pm_results$summary$speedup_vs_praat, na.rm = TRUE)

    cat("\nSummary Statistics (vs Praat):\n")
    cat("  Mean speedup:   ", sprintf("%.2fx\n", mean_speedup_praat))
    cat("  Median speedup: ", sprintf("%.2fx\n", median_speedup_praat))
    cat("  Min speedup:    ", sprintf("%.2fx\n", min_speedup_praat))
    cat("  Max speedup:    ", sprintf("%.2fx\n", max_speedup_praat))
  }
  cat("\n")

  # Create visualizations - reshape data for faceting
  if (!requireNamespace("tidyr", quietly = TRUE) ||
        !requireNamespace("dplyr", quietly = TRUE)) {
    cat("⚠ tidyr or dplyr not available for advanced plotting\n")
    cat("  Creating simple plot instead\n\n")

    # Simple plot - just parselmouth comparison
    p1 <- ggplot(
      pm_results$summary, aes(x = operation, y = speedup_vs_parselmouth)
    ) +
      geom_col(fill = "steelblue") +
      geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
      geom_text(aes(label = sprintf("%.2fx", speedup_vs_parselmouth)),
        vjust = -0.5, size = 3
      ) +
      labs(
        title = "pladdrr vs Parselmouth Performance",
        subtitle = paste0(
          "Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu_info
        ),
        x = "Operation",
        y = "Speedup (times faster than Parselmouth)",
        caption = paste0(
          "Package version: ", sys_info$package_version,
          " | Benchmark date: ", format(sys_info$timestamp, "%Y-%m-%d")
        )
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 9),
        axis.text.x = element_text(angle = 45, hjust = 1)
      )
  } else {
    library(tidyr)
    library(dplyr)

    plot_data <- pm_results$summary |>
      select(operation, speedup_vs_parselmouth, speedup_vs_praat) |>
      pivot_longer(
        cols = c(speedup_vs_parselmouth, speedup_vs_praat),
        names_to = "comparison",
        values_to = "speedup_value"
      ) |>
      filter(!is.na(speedup_value)) |>
      mutate(
        comparison = ifelse(comparison == "speedup_vs_parselmouth",
          "vs Parselmouth", "vs Praat"
        )
      )

    # Create side-by-side comparison plot
    p1 <- ggplot(
      plot_data, aes(x = operation, y = speedup_value, fill = comparison)
    ) +
      geom_col(position = "dodge") +
      geom_hline(yintercept = 1, linetype = "dashed", color = "red") +
      geom_text(aes(label = sprintf("%.2fx", speedup_value)),
        position = position_dodge(width = 0.9),
        vjust = -0.5, size = 3
      ) +
      scale_fill_manual(values = c(
        "vs Parselmouth" = "steelblue", "vs Praat" = "darkgreen"
      )) +
      labs(
        title = "pladdrr Performance: Three-Way Comparison",
        subtitle = paste0(
          "Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu_info
        ),
        x = "Operation",
        y = "Speedup (times faster than baseline)",
        fill = "Comparison",
        caption = paste0(
          "Package version: ", sys_info$package_version,
          " | Benchmark date: ", format(sys_info$timestamp, "%Y-%m-%d")
        )
      ) +
      theme_minimal() +
      theme(
        plot.title = element_text(hjust = 0.5, face = "bold"),
        plot.subtitle = element_text(hjust = 0.5, size = 9),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "top"
      )
  }

  ggsave("inst/benchmarks/results/parselmouth_comparison.png",
    p1,
    width = 10, height = 6, dpi = 300
  )
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
      vjust = -0.5, size = 3.5
    ) +
    labs(
      title = "speaker vs Parselmouth: Full Workflow Performance",
      subtitle = paste0(
        "Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu_info
      ),
      x = "Workflow",
      y = "Speedup (times faster)",
      caption = paste0(
        "Package version: ", sys_info$package_version,
        " | Benchmark date: ", format(sys_info$timestamp, "%Y-%m-%d")
      )
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(angle = 45, hjust = 1)
    )

  ggsave("inst/benchmarks/results/converted_scripts_comparison.png",
    p2,
    width = 8, height = 6, dpi = 300
  )
  cat(
    "Saved plot: inst/benchmarks/results/converted_scripts_comparison.png\n\n"
  )
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
      vjust = -0.5, size = 3
    ) +
    scale_fill_manual(values = c(
      "Individual Operations" = "steelblue",
      "Full Workflows" = "darkgreen"
    )) +
    labs(
      title = "speaker vs Parselmouth: Complete Performance Comparison",
      subtitle = paste0(
        "Platform: ", sys_info$platform, " | CPU: ", sys_info$cpu_info
      ),
      x = "Test",
      y = "Speedup (times faster)",
      fill = "Category",
      caption = paste0(
        "Package version: ", sys_info$package_version,
        " | Benchmark date: ", format(sys_info$timestamp, "%Y-%m-%d")
      )
    ) +
    theme_minimal() +
    theme(
      plot.title = element_text(hjust = 0.5, face = "bold"),
      plot.subtitle = element_text(hjust = 0.5, size = 9),
      axis.text.x = element_text(angle = 45, hjust = 1),
      legend.position = "bottom"
    )

  ggsave("inst/benchmarks/results/combined_comparison.png",
    p3,
    width = 10, height = 6, dpi = 300
  )
  cat("Saved plot: inst/benchmarks/results/combined_comparison.png\n\n")

  cat("Interpretation:\n")
  cat("  Values > 1.0: speaker is faster\n")
  cat("  Values < 1.0: Parselmouth is faster\n")
  cat("  Values = 1.0: Equal performance\n\n")

  cat("Key Findings:\n")
  if (mean(all_speedups) > 1.5) {
    cat(
      "  ✅ speaker shows significant performance advantage ",
      "(>1.5x on average)\n",
      sep = ""
    )
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
