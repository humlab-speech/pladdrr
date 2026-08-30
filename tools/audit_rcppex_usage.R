#!/usr/bin/env Rscript
# RcppExports.R usage audit (Phase 0 / plan §2.1)
# Buckets each function flagged as "unused" by goodpractice:
#   - USED_R:  called from non-generated R/ files
#   - USED_TEST: only referenced from tests (kept internal API)
#   - USED_INST: only referenced from inst/ examples/benchmarks
#   - DEAD:     no reference outside RcppExports.R itself
# Prints a per-bucket report and writes CSV to /tmp/rcppex_audit.csv
suppressMessages({
  lib <- .libPaths()
})
r_files <- list.files("R", pattern = "[.]R$", full.names = TRUE)
r_files <- setdiff(r_files, "R/RcppExports.R")
test_files <- list.files("tests", pattern = "[.]R$", recursive = TRUE, full.names = TRUE)
inst_files <- list.files(c("inst", "vignettes", "data-raw"), pattern = "[.]R$|[.]Rmd$",
                         recursive = TRUE, full.names = TRUE)

# Extract names defined in RcppExports.R (tokens after `<- function` / `= function`)
src <- readLines("R/RcppExports.R", warn = FALSE)
# roxygen-tagged exported wrappers: `name <- function` at top level
def <- regmatches(src, regexpr("^[[:alnum:]_.]+[[:space:]]*<-[[:space:]]*function", src))
def <- gsub("[[:space:]]*<-.*$", "", def)
def <- trimws(def)
def <- def[nzchar(def) & !startsWith(def, "#")]

audit <- data.frame(name = def, stringsAsFactors = FALSE)
audit$in_r <- vapply(audit$name, function(nm) {
  any(vapply(r_files, function(f) length(grep(nm, readLines(f, warn = FALSE), fixed = TRUE)) > 0, logical(1)))
}, logical(1))
audit$in_test <- vapply(audit$name, function(nm) {
  any(vapply(test_files, function(f) length(grep(nm, readLines(f, warn = FALSE), fixed = TRUE)) > 0, logical(1)))
}, logical(1))
audit$in_inst <- vapply(audit$name, function(nm) {
  any(vapply(inst_files, function(f) length(grep(nm, readLines(f, warn = FALSE), fixed = TRUE)) > 0, logical(1)))
}, logical(1))

audit$bucket <- ifelse(audit$in_r, "USED_R",
                ifelse(audit$in_test, "USED_TEST",
                ifelse(audit$in_inst, "USED_INST", "DEAD")))

# line number in RcppExports.R
audit$line <- vapply(audit$name, function(nm) {
  hit <- which(startsWith(trimws(src), paste0(nm, " <-")) | startsWith(trimws(src), paste0(nm, " =")))
  if (length(hit)) hit[1] else NA_integer_
}, integer(1))

cat("=== RcppExports.R usage audit ===\n")
print(table(audit$bucket))
write.csv(audit[order(audit$bucket, audit$line), ], "/tmp/rcppex_audit.csv", row.names = FALSE)
cat("\nDEAD functions:\n")
print(audit$name[audit$bucket == "DEAD"])
cat("\nUSED_TEST only (kept, finding accepted):\n")
print(audit$name[audit$bucket == "USED_TEST"])
