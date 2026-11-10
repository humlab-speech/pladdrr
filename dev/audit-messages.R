# Extract every condition message literal from R/*.R via the parser.
# Usage: Rscript dev/audit-messages.R [--dups]   (run from package root)
# Resolves stop/warning/message/packageStartupMessage and the pladdrr helpers;
# calls whose message is built at runtime (paste0 with variables) are reported
# as dynamic and excluded from the duplicate check.
msg_calls <- c("stop", "warning", "message", ".stop_input", ".warn_data_loss",
               "stopifnot_pladdrr", "packageStartupMessage")

audit_messages <- function(dir = "R") {
  rows <- list()
  for (f in list.files(dir, pattern = "\\.[Rr]$", full.names = TRUE)) {
    if (basename(f) == "RcppExports.R") next
    exprs <- parse(f, keep.source = TRUE)
    pd <- utils::getParseData(exprs)
    if (is.null(pd)) next
    walk <- function(e, fn = NA_character_) {
      if (is.call(e)) {
        head <- e[[1L]]
        nm <- if (is.name(head)) as.character(head) else NA_character_
        if (identical(nm, "<-") || identical(nm, "=")) {
          if (length(e) >= 3L && is.call(e[[3L]]) && identical(e[[3L]][[1L]], as.name("function")))
            fn <- paste(deparse(e[[2L]])[1L])
        }
        if (!is.na(nm) && nm %in% msg_calls) {
          args <- as.list(e)[-1L]
          nms <- names(args); if (is.null(nms)) nms <- rep("", length(args))
          # message text = positional character args, or `msg`
          pos <- args[nms == "" | nms == "msg"]
          pieces <- vapply(pos, function(a) {
            if (is.character(a)) a else if (is.call(a) &&
              as.character(a[[1L]])[1L] %in% c("paste0", "paste", "sprintf") &&
              all(vapply(as.list(a)[-1L], is.character, NA))) paste(unlist(as.list(a)[-1L]), collapse = "") else NA_character_
          }, character(1))
          if (nm == ".stop_input") pieces <- pieces[length(pieces)]
          lit <- if (length(pieces) && !anyNA(pieces)) paste(pieces, collapse = "") else NA_character_
          rows[[length(rows) + 1L]] <<- data.frame(
            file = basename(f), fn = fn, call = nm, text = lit,
            dynamic = is.na(lit), stringsAsFactors = FALSE)
        }
        for (a in as.list(e)) if (!missing(a)) walk(a, fn)
      } else if (is.pairlist(e) || is.expression(e)) {
        for (a in as.list(e)) if (!missing(a)) walk(a, fn)
      }
    }
    for (ex in exprs) walk(ex)
  }
  do.call(rbind, rows)
}

duplicated_messages <- function(x) {
  s <- x[!x$dynamic & nzchar(x$text), ]
  tab <- table(s$text)
  d <- names(tab)[tab > 1L]
  s[s$text %in% d, c("text", "file", "fn")]
}

if (sys.nframe() == 0L) {
  a <- audit_messages()
  cat(sprintf("%d message sites (%d literal, %d dynamic)\n", nrow(a),
              sum(!a$dynamic), sum(a$dynamic)))
  d <- duplicated_messages(a)
  cat(sprintf("%d distinct duplicated literals across %d sites\n",
              length(unique(d$text)), nrow(d)))
  if ("--dups" %in% commandArgs(TRUE)) {
    tb <- sort(table(d$text), decreasing = TRUE)
    for (i in seq_along(tb)) cat(sprintf("%4d  %s\n", tb[[i]], names(tb)[i]))
  }
}
