#!/usr/bin/env Rscript
# Phase 6: move duplicate print.*/as.data.frame.* S3 methods into
# R/s3-methods.R (single file) so cross-file duplicate-body check passes.
suppressMessages({})
d <- read.csv("/tmp/pos_duplicate_function_bodies.csv", stringsAsFactors = FALSE)
target <- "R/s3-methods.R"
target_lines <- readLines(target, warn = FALSE)
moved <- list()
for (i in seq_len(nrow(d))) {
  path <- d$file[i]
  if (path == target) next                      # already there
  name <- d$msg[i]
  lines <- readLines(path, warn = FALSE)
  pat <- paste0("^", gsub(".", "\\.", name, fixed = TRUE), "\\s*(<-|=)\\s*function")
  def <- which(grepl(pat, lines))
  if (length(def) == 0) { cat("NO DEF:", path, name, "\n"); next }
  # include preceding roxygen @export block (lines starting #')
  s <- def[1]
  while (s > 1 && grepl("^#'", lines[s - 1])) s <- s - 1
  # find end via brace balance
  e <- def[1]; depth <- 0
  for (k in def[1]:length(lines)) {
    depth <- depth + lengths(regmatches(lines[k], gregexpr("{", lines[k], fixed = TRUE))) -
      lengths(regmatches(lines[k], gregexpr("}", lines[k], fixed = TRUE)))
    if (depth <= 0) { e <- k; break }
  }
  block <- lines[s:e]
  moved[[length(moved) + 1]] <- block
  # remove from source (also swallow a following blank line)
  del_end <- e
  while (del_end + 1 <= length(lines) && lines[del_end + 1] == "") del_end <- del_end + 1
  lines <- lines[-((s:del_end))]
  writeLines(lines, path)
  cat("moved", name, "from", path, "lines", s, "-", e, "\n")
}
# append all moved methods to target with a header
header <- c(
  "# ============================================================================",
  "# Consolidated S3 methods (print.* / as.data.frame.*)",
  "# Moved here from per-class wrapper files so identical bodies share one file",
  "# (cross-file duplicate-body lint). Each delegates to the R6 object's",
  "# $print() / $as_data_frame() method.",
  "# ============================================================================"
)
new_target <- c(target_lines, header, unlist(moved))
writeLines(new_target, target)
cat("appended", length(moved), "methods to", target, "\n")
