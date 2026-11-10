# Rank hand-written internal functions (.name <- function) by call count and
# report which lack a roxygen (#') block directly above. Run from package root.
files <- setdiff(list.files("R", "\\.[Rr]$", full.names = TRUE), "R/RcppExports.R")
src <- lapply(files, readLines, warn = FALSE); names(src) <- files
defs <- do.call(rbind, lapply(files, function(f) {
  l <- src[[f]]; i <- grep("^\\.[A-Za-z0-9_.]+ <- function", l)
  if (!length(i)) return(NULL)
  data.frame(file = f, line = i, name = sub(" <- function.*", "", l[i]),
             documented = vapply(i, function(k) k > 1 && grepl("^#'", l[k - 1]), NA))
}))
all_text <- paste(unlist(src), collapse = "\n")
count <- function(nm) lengths(regmatches(all_text, gregexpr(nm, all_text, fixed = TRUE))) - 1L
defs$uses <- vapply(defs$name, count, 0L)
defs <- defs[order(-defs$uses), ]
if (sys.nframe() == 0L) {
  cat(sprintf("%d internals, %d documented\n", nrow(defs), sum(defs$documented)))
  print(head(defs[!defs$documented, ], 70), row.names = FALSE)
}
