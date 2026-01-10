#' data.table Utility Functions for pladdrr
#' 
#' Internal helper functions for data.table operations.
#' These functions provide consistent data.table handling across the package.
#' 
#' @keywords internal
#' @name datatable-utils
NULL

#' Ensure object is a data.table
#' 
#' Converts to data.table if not already one (modifies in place).
#' 
#' @param df A data.frame or data.table
#' @return data.table (invisibly)
#' @keywords internal
ensure_datatable <- function(df) {
  if (!data.table::is.data.table(df)) {
    data.table::setDT(df)
  }
  invisible(df)
}

#' Convert data.frame to data.table
#' 
#' Creates a copy as data.table (does not modify original).
#' 
#' @param df A data.frame
#' @return data.table
#' @keywords internal
df_to_dt <- function(df) {
  data.table::as.data.table(df)
}

#' Create empty data.table with typed columns
#' 
#' Replacement for data.frame() constructor.
#' 
#' @param ... Named vectors defining column types (e.g., time=numeric())
#' @return Empty data.table with specified columns
#' @keywords internal
#' 
#' @examples
#' \dontrun{
#' # Before: results <- data.frame(time=numeric(), value=numeric())
#' # After:  results <- dt_empty(time=numeric(), value=numeric())
#' results <- dt_empty(time=numeric(), formant=integer(), frequency=numeric())
#' }
dt_empty <- function(...) {
  data.table::data.table(...)
}

#' Efficiently bind list of rows into data.table
#' 
#' Replacement for repeated rbind() calls in loops.
#' 
#' @param l List of lists or data.frames to bind
#' @param fill Logical, fill missing columns with NA (default TRUE)
#' @return data.table
#' @keywords internal
#' 
#' @examples
#' \dontrun{
#' # Before: 
#' # results <- data.frame()
#' # for (i in 1:100) results <- rbind(results, data.frame(x=i, y=i^2))
#' 
#' # After:
#' # results_list <- vector("list", 100)
#' # for (i in 1:100) results_list[[i]] <- list(x=i, y=i^2)
#' # results <- dt_rbindlist(results_list)
#' }
dt_rbindlist <- function(l, fill = TRUE) {
  data.table::rbindlist(l, fill = fill)
}

#' Set key columns on data.table
#' 
#' Sets key for fast operations (modifies in place).
#' 
#' @param dt A data.table
#' @param ... Column names to use as key
#' @return data.table (invisibly, modified by reference)
#' @keywords internal
#' 
#' @examples
#' \dontrun{
#' dt <- data.table::data.table(time=1:100, formant=rep(1:4, 25), freq=rnorm(100))
#' dt_setkey(dt, time, formant)  # Fast lookups on time+formant
#' }
dt_setkey <- function(dt, ...) {
  data.table::setkeyv(dt, as.character(substitute(list(...)))[-1L])
  invisible(dt)
}

#' Conditionally return data.table or data.frame
#' 
#' For backward compatibility, allows users to opt into data.frame returns.
#' This is deprecated and will be removed in v5.0.
#' 
#' @param dt A data.table
#' @return data.table or data.frame depending on options
#' @keywords internal
.finalize_dataframe <- function(dt) {
  # Check if user explicitly wants data.frame (deprecated)
  if (isFALSE(getOption("pladdrr.return_datatable", default = TRUE))) {
    # Warning only shown once per session
    if (is.null(getOption("pladdrr.dataframe_warning_shown"))) {
      warning(
        "Returning data.frame instead of data.table is deprecated.\n",
        "Set options(pladdrr.return_datatable = TRUE) or remove the option.\n",
        "data.frame mode will be removed in pladdrr v5.0.0",
        call. = FALSE
      )
      options(pladdrr.dataframe_warning_shown = TRUE)
    }
    return(as.data.frame(dt, stringsAsFactors = FALSE))
  }
  
  dt
}

#' Create data.table from named vectors
#' 
#' Convenience function similar to data.frame() but returns data.table.
#' Automatically sets appropriate key columns.
#' 
#' @param ... Named vectors
#' @param key Character vector of key column names (optional)
#' @return data.table
#' @keywords internal
dt_create <- function(..., key = NULL) {
  dt <- data.table::data.table(...)
  
  if (!is.null(key)) {
    data.table::setkeyv(dt, key)
  }
  
  dt
}
