# Heuristic G5.2b ratchet: which literal condition messages in R/ have no
# matching fragment anywhere in tests/testthat? A message counts as tested when
# the first 24 characters after the "fn(): " prefix appear verbatim in a test
# file. Cheap and approximate by design; replace with covr line-level data if
# it ever becomes the bottleneck.
source("dev/audit-messages.R")

untested_messages <- function(r_dir = "R", test_dir = "tests/testthat") {
  a <- audit_messages(r_dir)
  a <- a[!a$dynamic & nzchar(a$text), ]
  files <- list.files(test_dir, pattern = "\\.[Rr]$", full.names = TRUE)
  tests <- paste(unlist(lapply(files, readLines, warn = FALSE)), collapse = "\n")
  key <- function(t) {
    t <- sub("^[^ ]+\\(\\): ", "", t)
    substr(gsub("\\\\(.)", "\\1", t), 1L, 24L)
  }
  hit <- vapply(a$text, function(t) grepl(key(t), tests, fixed = TRUE), NA)
  out <- a[!hit, c("file", "fn", "text")]
  out$text <- gsub("\n", "\\n", out$text, fixed = TRUE)
  out
}

if (sys.nframe() == 0L) {
  u <- untested_messages()
  cat(sprintf("%d untested literal messages\n", nrow(u)))
  if ("--write" %in% commandArgs(TRUE))
    writeLines(sort(unique(u$text)), "dev/message-baseline.txt")
}
