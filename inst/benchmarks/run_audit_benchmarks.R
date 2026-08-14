# Phase B — efficiency audit runner.
#
# Times every routine in the faithfulness registry against the Praat-native
# execution time on the same input, and writes inst/benchmarks/RESULTS.md.
#
# Per-row columns:
#   praat_ms        — time spent in Praat (system2 to the binary), repeated.
#   pladdrr_ms      — time spent in pladdrr tier-1 method.
#   speedup_vs_praat — praat_ms / pladdrr_ms.
#
# Notes:
# - Praat startup dominates short routines; this is intentional — Praat-from-R
#   is the user-visible alternative the package replaces, so its startup cost
#   is part of the comparison. Routines whose only goal is to skip startup
#   should still show a large win.
# - Parselmouth comparison is left as a TODO row (commented call) to avoid
#   forcing a Python dep on the benchmark machine.
#
# Run from the package root:
#   Rscript inst/benchmarks/run_audit_benchmarks.R
#
# Skips quietly if Praat or pladdrr is unavailable.

PRAAT_EXEC <- "/Applications/Praat.app/Contents/MacOS/Praat"
PKG_ROOT <- normalizePath(file.path(dirname(sys.frame(1)$ofile %||% "."), "..", ".."),
  mustWork = FALSE
)
if (!nzchar(PKG_ROOT) || !dir.exists(PKG_ROOT)) PKG_ROOT <- normalizePath(".")

`%||%` <- function(a, b) if (is.null(a)) b else a

if (!file.exists(PRAAT_EXEC)) {
  message("Praat not available at ", PRAAT_EXEC, "; skipping benchmark.")
  quit(save = "no", status = 0)
}
if (!requireNamespace("pladdrr", quietly = TRUE)) {
  message("pladdrr not installed; skipping benchmark.")
  quit(save = "no", status = 0)
}

routines_path <- file.path(
  PKG_ROOT, "tests", "testthat", "faithfulness",
  "routines.R"
)
if (!file.exists(routines_path)) {
  message("Routine registry missing at ", routines_path)
  quit(save = "no", status = 0)
}
source(routines_path, local = TRUE)

resolve_fixture <- function(rel) {
  c1 <- system.file(rel, package = "pladdrr")
  if (nzchar(c1) && file.exists(c1)) {
    return(c1)
  }
  c2 <- file.path(PKG_ROOT, "inst", rel)
  if (file.exists(c2)) {
    return(normalizePath(c2))
  }
  NA_character_
}

run_praat <- function(script_text, path) {
  tf <- tempfile(fileext = ".praat")
  on.exit(unlink(tf), add = TRUE)
  writeLines(gsub("{path}", path, script_text, fixed = TRUE), tf)
  out <- suppressWarnings(system2(PRAAT_EXEC,
    args = c("--utf8", "--run", tf),
    stdout = TRUE, stderr = TRUE
  ))
  if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
    stop("Praat oracle failed")
  }
  out
}

time_one <- function(expr, reps = 5L) {
  t <- numeric(reps)
  for (i in seq_len(reps)) {
    g <- gc(verbose = FALSE)
    a <- Sys.time()
    force(eval(expr))
    b <- Sys.time()
    t[i] <- as.numeric(b - a, units = "secs") * 1000
  }
  list(median_ms = median(t), min_ms = min(t), max_ms = max(t))
}

rows <- list()
for (r in FAITHFULNESS_ROUTINES) {
  path <- resolve_fixture(r$fixture)
  if (is.na(path)) next

  praat_t <- tryCatch(
    time_one(quote(run_praat(r$praat_script, path)),
      reps = 3L
    ),
    error = function(e) list(median_ms = NA, min_ms = NA, max_ms = NA)
  )

  pladdrr_t <- tryCatch(
    time_one(bquote(.(r$pladdrr)(.(path))),
      reps = 5L
    ),
    error = function(e) list(median_ms = NA, min_ms = NA, max_ms = NA)
  )

  speedup <- if (!is.na(praat_t$median_ms) && !is.na(pladdrr_t$median_ms) &&
    pladdrr_t$median_ms > 0) {
    praat_t$median_ms / pladdrr_t$median_ms
  } else {
    NA_real_
  }

  rows[[length(rows) + 1L]] <- data.frame(
    routine = r$name,
    praat_ms_median = praat_t$median_ms,
    pladdrr_ms_median = pladdrr_t$median_ms,
    speedup_vs_praat = speedup,
    stringsAsFactors = FALSE
  )
}

df <- do.call(rbind, rows)
out_md <- file.path(PKG_ROOT, "inst", "benchmarks", "RESULTS.md")
lines <- c(
  "# Benchmark Results (pladdrr vs Praat-native)",
  "",
  sprintf("_Generated: %s_  ", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
  sprintf("_Platform: %s_  ", R.version$platform),
  sprintf("_Praat: %s_", PRAAT_EXEC),
  "",
  "Praat timing includes binary startup cost (~50–100 ms on a modern Mac) —",
  "this is part of the user-visible cost of the 'shell out to Praat'",
  "alternative and is therefore *not* netted out. Routines that are pure",
  "Praat-startup wins still show a real-world speedup.",
  "",
  "| Routine | Praat (ms) | pladdrr (ms) | Speedup |",
  "|---------|-----------:|-------------:|--------:|"
)
for (i in seq_len(nrow(df))) {
  lines <- c(lines, sprintf(
    "| %s | %s | %s | %s× |",
    df$routine[i],
    format(df$praat_ms_median[i], digits = 4),
    format(df$pladdrr_ms_median[i], digits = 4),
    format(df$speedup_vs_praat[i], digits = 3)
  ))
}
writeLines(lines, out_md)
cat("Wrote ", out_md, "\n", sep = "")
