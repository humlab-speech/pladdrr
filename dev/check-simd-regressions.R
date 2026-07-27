#!/usr/bin/env Rscript

if (!requireNamespace("pladdrr", quietly = TRUE)) {
  stop("Install pladdrr first: R CMD INSTALL --no-docs .", call. = FALSE)
}

library(pladdrr)

resolve_fixture <- function() {
  installed <- system.file("signalfiles/DSI/input/ppq1.wav", package = "pladdrr")
  if (nzchar(installed) && file.exists(installed)) {
    return(installed)
  }

  local <- file.path("inst", "signalfiles", "DSI", "input", "ppq1.wav")
  if (file.exists(local)) {
    return(normalizePath(local))
  }

  stop("Could not find ppq1.wav in the installed package or inst/.", call. = FALSE)
}

measure_kernel <- function(enabled, expr, reps = 7L) {
  pladdrr_simd(enabled)
  ex <- substitute(expr)
  pf <- parent.frame()
  eval(ex, pf)
  median(replicate(reps, system.time(eval(ex, pf))[["elapsed"]]))
}

fixture <- resolve_fixture()
sound <- Sound(fixture)
threshold <- as.numeric(Sys.getenv("PLADDRR_SIMD_REGRESSION_RATIO", "1.05"))

if (!simd_info()$available) {
  message("SIMD not available on this build; nothing to compare.")
  quit(save = "no", status = 0)
}

old_simd <- simd_info()$enabled
old_threads <- pladdrr_threads()
on.exit({
  pladdrr_simd(old_simd)
  restore_threads <- if (!old_threads$enabled) {
    1L
  } else if (old_threads$max_threads >= old_threads$processors) {
    0L
  } else {
    as.integer(old_threads$max_threads)
  }
  pladdrr_threads(restore_threads)
}, add = TRUE)

pladdrr_threads(0L)

results <- data.frame(
  kernel = c("pitch_cc", "cpps_ultra"),
  simd_on_ms = c(
    1000 * measure_kernel(TRUE, to_pitch_cc_direct(sound, 0, 75, 600, voicing_threshold = 0.45)),
    1000 * measure_kernel(TRUE, calculate_cpps_ultra(sound, time_averaging_window = 0.01, quefrency_averaging_window = 0.001))
  ),
  simd_off_ms = c(
    1000 * measure_kernel(FALSE, to_pitch_cc_direct(sound, 0, 75, 600, voicing_threshold = 0.45)),
    1000 * measure_kernel(FALSE, calculate_cpps_ultra(sound, time_averaging_window = 0.01, quefrency_averaging_window = 0.001))
  )
)

results$ratio_on_vs_off <- results$simd_on_ms / results$simd_off_ms
print(results, row.names = FALSE)

regressions <- results[results$ratio_on_vs_off > threshold, , drop = FALSE]
regressions <- regressions[is.finite(regressions$ratio_on_vs_off), , drop = FALSE]
if (nrow(regressions)) {
  stop(
    sprintf(
      "SIMD regression detected above %.2fx threshold for: %s",
      threshold,
      paste(regressions$kernel, collapse = ", ")
    ),
    call. = FALSE
  )
}

message("SIMD guard passed.")
