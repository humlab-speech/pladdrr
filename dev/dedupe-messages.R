# One-off: make duplicated condition-message literals unique by prefixing the
# enclosing function's name ("fn(): text"). Only touches calls whose first
# argument is a single string literal. Run from the package root after
# dev/audit-messages.R shows duplicates; re-run the audit to confirm.
source("dev/audit-messages.R")

label_for <- function(pd, id) {
  # climb to the nearest `name <- function(...)` / `a$b <- function(...)`
  repeat {
    row <- pd[pd$id == id, ]
    if (!nrow(row) || row$parent == 0L) return(NA_character_)
    id <- row$parent
    kids <- pd[pd$parent == id, ]
    if (any(kids$token %in% c("LEFT_ASSIGN", "EQ_ASSIGN")) && nrow(kids) == 3L) {
      rhs <- pd[pd$id == kids$id[3L], ]
      rk <- pd[pd$parent == rhs$id, ]
      if (any(rk$token == "FUNCTION")) {
        lhs <- kids$id[1L]
        toks <- pd[pd$parent == lhs | pd$id == lhs, ]
        txt <- getParseText(pd, lhs)
        return(txt)
      }
    }
  }
}

pretty_label <- function(x) {
  if (is.na(x)) return(NA_character_)
  x <- gsub("[\"'`]", "", x)
  x <- sub("^\\.([a-z0-9]+)_methods\\$", "\\1$", x)   # .sound_methods$save -> sound$save
  x <- sub("\\[\\[(.*)\\]\\]$", "$\\1", x)
  paste0(x, "()")
}

dedupe_file <- function(f, dup_texts) {
  exprs <- parse(f, keep.source = TRUE)
  pd <- getParseData(exprs, includeText = NA)
  lines <- readLines(f, warn = FALSE)
  calls <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% msg_calls, ]
  edits <- list()
  for (i in seq_len(nrow(calls))) {
    fexpr <- calls$parent[i]
    call <- pd$parent[pd$id == fexpr]
    kids <- pd[pd$parent == call, ]
    kids <- kids[order(kids$line1, kids$col1), ]
    if (nrow(kids) < 3L || kids$token[2L] != "'('") next
    arg <- kids[3L, ]
    if (arg$token != "expr") next
    ak <- pd[pd$parent == arg$id, ]
    if (nrow(ak) != 1L || ak$token != "STR_CONST") next
    lit <- ak$text
    if (grepl("^[rR][\"']", lit)) next
    inner <- substr(lit, 2L, nchar(lit) - 1L)
    if (!(inner %in% dup_texts) && !(gsub("\\\\(.)", "\\1", inner) %in% dup_texts)) next
    lab <- pretty_label(label_for(pd, call))
    if (is.na(lab)) lab <- paste0(sub("\\.[Rr]$", "", basename(f)), "()")
    if (ak$line1 != ak$line2) next
    edits[[length(edits) + 1L]] <- list(line = ak$line1, col = ak$col1, lab = lab)
  }
  if (!length(edits)) return(0L)
  ord <- order(vapply(edits, `[[`, 1L, "line"), vapply(edits, `[[`, 1L, "col"),
               decreasing = TRUE)
  for (e in edits[ord]) {
    ln <- lines[e$line]
    lines[e$line] <- paste0(substr(ln, 1L, e$col), e$lab, ": ", substr(ln, e$col + 1L, nchar(ln)))
  }
  writeLines(lines, f)
  length(edits)
}

a <- audit_messages()
d <- duplicated_messages(a)
dup_texts <- unique(d$text)
n <- 0L
for (f in unique(file.path("R", d$file))) n <- n + dedupe_file(f, dup_texts)
cat("edited", n, "sites\n")
