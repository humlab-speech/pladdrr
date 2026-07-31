# CPPS Ultra Performance Benchmark
# Tracks calculate_cpps_ultra() timing on the DSI reference file, and cross-checks
# fidelity vs the known-good Praat-matching values. See PLADDRR_CPPS_PERF_SPEC.md
# for the investigation this benchmark supports (target: warm elapsed <= 0.5s,
# stretch <= 0.35s, vs pre-optimization baseline of ~1.36s on ppq1.wav).

cat("\n=== CPPS Ultra Performance Benchmark ===\n\n")

library(pladdrr)
library(microbenchmark)

wav_path <- system.file("signalfiles", "DSI", "input", "ppq1.wav", package = "pladdrr")
if (!nzchar(wav_path)) {
  wav_path <- file.path("inst", "signalfiles", "DSI", "input", "ppq1.wav")
}
stopifnot(file.exists(wav_path))

s <- Sound$new(wav_path)

# Known-good reference values (bit-exact vs Praat as of v4.9.14; see
# PLADDRR_CPPS_PERF_SPEC.md). robust1 = default ROBUST_FAST/straight,
# lsq = LEAST_SQUARES/straight.
reference <- list(
  robust1 = 20.710097057017084,
  lsq     = 19.463230951328100
)

cat("Fidelity check (vs saved Praat-matching baseline):\n")
robust1 <- calculate_cpps_ultra(s, pitch_floor = 60, pitch_ceiling = 333, time_step = 0.002)
lsq <- calculate_cpps_ultra(s, pitch_floor = 60, pitch_ceiling = 333, time_step = 0.002,
                             fit_method = "least_squares")

cat(sprintf("  robust1: %.15f (ref %.15f, diff %.2e)\n",
            robust1, reference$robust1, abs(robust1 - reference$robust1)))
cat(sprintf("  lsq:     %.15f (ref %.15f, diff %.2e)\n",
            lsq, reference$lsq, abs(lsq - reference$lsq)))

if (abs(robust1 - reference$robust1) > 1e-9 || abs(lsq - reference$lsq) > 1e-9) {
  warning("CPPS fidelity regression detected vs saved reference values!")
}

cat("\nTiming (warm, 10 reps):\n")
timing <- microbenchmark(
  calculate_cpps_ultra(s, pitch_floor = 60, pitch_ceiling = 333, time_step = 0.002),
  times = 10
)
print(timing)

elapsed_s <- summary(timing)$mean / 1000  # ms -> s
cat(sprintf("\nMean warm elapsed: %.3f s (target <= 0.5s, stretch <= 0.35s)\n", elapsed_s))

# --- Long-signal case (regression guard for the slopeselector SIMD gate) --------
# The short ppq1 case above hid the v4.9.15 arm64 SIMD regression: the per-frame
# Siegel trend fit only dominates on many-frame (long) signals. Concatenate ppq1
# to ~8x length so the trend-fit hot path is exercised at scale. The default gate
# is scalar on arm64 (see slopeselector_simd.cpp); force-enable via
# PLADDRR_ENABLE_SLOPESELECTOR_SIMD=1 in a *separate* R process to A/B (the gate is
# read once at static init, so it cannot be toggled mid-session).
cat("\n=== Long-signal case (~8x ppq1) ===\n")
long <- sound_concatenate_all(rep(list(s), 8))
cat(sprintf("Long signal duration: %.2f s\n", long$get_end_time() - long$get_start_time()))
long_timing <- microbenchmark(
  calculate_cpps_ultra(long, pitch_floor = 60, pitch_ceiling = 333, time_step = 0.002),
  times = 10
)
print(long_timing)
long_elapsed_s <- summary(long_timing)$mean / 1000
simd_state <- Sys.getenv("PLADDRR_ENABLE_SLOPESELECTOR_SIMD", "0")
cat(sprintf("\nLong-signal mean warm elapsed: %.3f s (slopeselector SIMD force-enable=%s)\n",
            long_elapsed_s, simd_state))
cat("Compare across pladdrr versions / arches; a >20%% jump here is a trend-fit regression.\n")
