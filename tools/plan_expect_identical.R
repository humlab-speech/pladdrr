#!/usr/bin/env Rscript
# Convert expect_equal(x, y) -> expect_identical(x, y) where exact.
# Exact if: expected value is a string literal, OR expected is an integer
# literal and the compared expression is integer-typed (count/dimension).
# Keep expect_equal for float comparisons / any call with tolerance=.
suppressMessages({})
df <- readRDS("/tmp/lint_df.rds")
d <- df[df$linter == "expect_identical_linter", ]
dirs <- c("tests/testthat", "R", "inst/examples", "inst/benchmarks",
          "vignettes/articles", "vignettes", "data-raw")
find_file <- function(base) {
  for (d0 in dirs) if (file.exists(file.path(d0, base))) return(file.path(d0, base))
  NA_character_
}
count_pat <- "nrow|ncol|length\\s*\\(|_count\\b|get_number_of|get_dimension|get_ny|get_nx|nlevels|get_num_|object_count|n_points|get_number|dim\\s*\\("

res <- list()
for (i in seq_len(nrow(d))) {
  base <- d$filename[i]; ln <- d$line_number[i]
  path <- find_file(base)
  if (is.na(path)) next
  lines <- readLines(path, warn = FALSE)
  if (ln > length(lines)) next
  lpos <- regexpr("expect_equal(", lines[ln], fixed = TRUE)
  if (lpos == -1) next
  txt <- paste(lines, collapse = "\n")
  line_start <- cumsum(c(0, nchar(lines) + 1))
  # textual bracket-matching from expect_equal( to the call's closing paren
  start <- line_start[ln] + lpos - 1
  chars <- strsplit(substr(txt, start, nchar(txt)), "")[[1]]
  depth <- 0; in_str <- ""; end <- NULL
  for (j in seq_along(chars)) {
    ch <- chars[j]
    if (in_str != "") { if (ch == in_str) in_str <- ""; next }
    if (ch %in% c('"', "'")) { in_str <- ch; next }
    if (ch == "(") depth <- depth + 1
    else if (ch == ")") { depth <- depth - 1; if (depth == 0) { end <- j; break } }
  }
  if (is.null(end)) next
  full <- sub("^\\s+", "", substr(txt, start, start + end - 1))

  # split args on top-level commas
  depth <- 0; parts <- c(); cur <- ""; in_str <- ""
  for (ch in strsplit(full, "")[[1]]) {
    if (in_str != "") { cur <- paste0(cur, ch); if (ch == in_str) in_str <- ""; next }
    if (ch %in% c('"', "'")) { in_str <- ch; cur <- paste0(cur, ch); next }
    if (ch == "(") { depth <- depth + 1; cur <- paste0(cur, ch); next }
    if (ch == ")") { depth <- depth - 1; cur <- paste0(cur, ch); next }
    if (ch == "," && depth == 1) { parts <- c(parts, cur); cur <- ""; next }
    cur <- paste0(cur, ch)
  }
  parts <- c(parts, cur)
  if (length(parts) < 2) next
  # parts[1] = "expect_equal(" + first arg (commas split at depth 1)
  parts[length(parts)] <- sub("\\)$", "", parts[length(parts)])  # drop call's closing paren
  x <- trimws(sub("^expect_equal\\(", "", parts[1]))
  y <- trimws(parts[2])
  has_tol <- any(grepl("tolerance", parts))
  y_str <- grepl('^"', y) || grepl("^'", y)
  y_int <- grepl("^-?[0-9]+[lL]?$", y)
  x_is_count <- grepl(count_pat, x)
  convert <- !has_tol && (y_str || (y_int && x_is_count))
  new <- full
  if (convert) {
    new <- sub("expect_equal\\(", "expect_identical(", full)
    if (y_int && !grepl("[lL]$", y)) new <- sub(y, paste0(y, "L"), new, fixed = TRUE)
  }
  res[[length(res) + 1]] <- data.frame(file = path, line = ln, convert = convert,
                                       full = full, new = new, stringsAsFactors = FALSE)
}
out <- do.call(rbind, res)
cat("convert:", sum(out$convert), " keep:", sum(!out$convert), " skipped:", nrow(d) - nrow(out), "\n")
write.csv(out, "/tmp/ei_plan.csv", row.names = FALSE)
