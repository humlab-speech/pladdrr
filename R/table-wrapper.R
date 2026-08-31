#' @title Praat Table Object
#' @description
#' Praat Table object with direct C++ module binding for tabular data
#'  operations.
#'
#' @details
#' Table objects store tabular data with named columns and support various
#' statistical operations.
#'
#' @param numberOfRows Number of rows. Required unless \code{.xptr} is given.
#' @param numberOfColumns Number of columns. Required unless \code{columnNames}
#'   or \code{.xptr} is given.
#' @param columnNames Character vector of column names, used instead of
#'   \code{numberOfColumns} to name columns as they are created.
#' @param .xptr Not for direct use. External pointer to the underlying C++
#'   Table object; set internally when a method returns a new Table.
#' @return A \code{Table} object with methods for tabular data access and
#'  statistics.
#'
#' @examples
#' tbl <- Table(numberOfRows = 3, columnNames = c("word", "duration"))
#' tbl$set_string_value(1, "word", "cat")
#' tbl$set_numeric_value(1, "duration", 0.42)
#' tbl$get_number_of_rows()
#' tbl$get_string_value(1, "word")
#' tbl$get_numeric_value(1, "duration")
#'
#' @name Table
NULL

# ============================================================================
# Helpers
# ============================================================================

# Helper: Table xptr -> data.frame
#
# Praat Table cells are stored as strings internally. A column is treated as
# numeric in the resulting data.frame only if every cell's string parses as
# an R number via as.numeric(). Note: .table_get_numeric_value() (Praat's
# Table_getNumericValue_a) is NOT used for this test — for non-numeric text
# it does not return NA/NaN, it returns a categorical level index (cells are
# enumerated alphabetically, e.g. "bird"/"cat"/"dog" -> 1/2/3), which would
# silently corrupt string columns into bogus integers.
.table_to_data_frame <- function(xptr) {
  n_rows <- .table_get_number_of_rows(xptr)
  n_cols <- .table_get_number_of_columns(xptr)
  col_names <- .table_get_column_names(xptr)

  columns <- vector("list", n_cols)
  for (j in seq_len(n_cols)) {
    if (n_rows == 0) {
      # No cells to inspect -> real column type is unknown; don't guess
      # numeric (anyNA(as.numeric(character(0))) is FALSE, which would
      # otherwise misclassify every empty column as numeric).
      columns[[j]] <- character(0)
      next
    }
    str_vals <- vapply(seq_len(n_rows),
                        function(i) .table_get_string_value(xptr, i, j),
                        character(1))
    num_vals <- suppressWarnings(as.numeric(str_vals))
    columns[[j]] <- if (anyNA(num_vals)) str_vals else num_vals
  }
  names(columns) <- as.character(col_names)

  as.data.frame(columns, stringsAsFactors = FALSE, check.names = FALSE)
}

# ============================================================================
# Shared Method Dispatch Table
# ============================================================================

.table_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Structure
.table_methods$get_number_of_rows <- function(
  .self) .self$.cpp$get_number_of_rows()
.table_methods$get_number_of_columns <- function(
  .self) .self$.cpp$get_number_of_columns()
.table_methods$get_column_label <- function(.self,
  col) .self$.cpp$get_column_label(as.integer(col))
.table_methods$get_column_index <- function(.self,
  label) .self$.cpp$get_column_index(as.character(label))
.table_methods$get_column_names <- function(.self) .self$.cpp$get_column_names()

# Modification - Structure
.table_methods$set_column_label <- function(.self, col, label) {
  .self$.cpp$set_column_label(as.integer(col), as.character(label))
  invisible(.self)
}
.table_methods$append_row <- function(.self) {
  .self$.cpp$append_row()
  invisible(.self)
}
.table_methods$append_column <- function(.self, label) {
  .self$.cpp$append_column(as.character(label))
  invisible(.self)
}
.table_methods$insert_row <- function(.self, row) {
  .self$.cpp$insert_row(as.integer(row))
  invisible(.self)
}
.table_methods$insert_column <- function(.self, col, label) {
  .self$.cpp$insert_column(as.integer(col), as.character(label))
  invisible(.self)
}

# Query/Set - Values
.table_methods$get_numeric_value <- function(.self, row, column) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$get_numeric_value(as.integer(row), col_idx)
}
.table_methods$get_string_value <- function(.self, row, column) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$get_string_value(as.integer(row), col_idx)
}
.table_methods$set_numeric_value <- function(.self, row, column, value) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$set_numeric_value(as.integer(row), col_idx, as.numeric(value))
  invisible(.self)
}
.table_methods$set_string_value <- function(.self, row, column, value) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$set_string_value(as.integer(row), col_idx, as.character(value))
  invisible(.self)
}

# Statistics
.table_methods$get_mean <- function(.self, column) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .table_get_mean(.self$.xptr, col_idx)
}
.table_methods$get_standard_deviation <- function(.self, column) {
  col_idx <- if (
    is.character(
      column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .table_get_stdev(.self$.xptr, col_idx)
}

# Export
.table_methods$as_data_frame <- function(
  .self) .table_to_data_frame(.self$.xptr)
.table_methods$save <- function(.self, path) {
  .self$.cpp$save(as.character(path))
  invisible(.self)
}

# Sort
.table_methods$sort_rows <- function(.self, columns) {
  .table_sort_rows(.self$.xptr, as.character(columns))
  invisible(.self)
}

# Row extraction
.table_methods$extract_rows_where_number <- function(.self, column, which,
  criterion) {
  if (is.character(column)) {
    column <- .self$.cpp$get_column_index(column)
  }
  tbl_ptr <- .table_extract_rows_where_column_number(
    .self$.xptr, as.integer(column), as.integer(which), as.numeric(criterion)
  )
  Table(.xptr = tbl_ptr)
}

.table_methods$extract_rows_where_string <- function(.self, column, which,
  criterion) {
  if (is.character(column)) {
    column <- .self$.cpp$get_column_index(column)
  }
  tbl_ptr <- .table_extract_rows_where_column_string(
    .self$.xptr, as.integer(column), as.integer(which), as.character(criterion)
  )
  Table(.xptr = tbl_ptr)
}

# Utility
.table_methods$get_xptr <- function(.self) .self$.xptr

# Print
.table_methods$print <- function(.self) {
  cat("<Praat Table>\n")
  cat(sprintf("  Dimensions: %d rows x %d columns\n",
              .self$.cpp$get_number_of_rows(
                ), .self$.cpp$get_number_of_columns()))
  col_names <- .self$.cpp$get_column_names()
  if (length(col_names) > 0) {
    cat(sprintf("  Columns: %s\n", toString(col_names)))
  }
  invisible(.self)
}

.table_methods$is_valid <- function(.self) .self$.cpp$is_valid()
lockEnvironment(.table_methods, bindings = TRUE)

# ============================================================================
# S3 Dispatch
# ============================================================================

#' @method $ Table
#' @export
`$.Table` <- function(x, name) {
  val <- .subset2(x, name)
  if (!is.null(val)) return(val)
  method <- .table_methods[[name]]
  if (is.null(method)) return(NULL)
  function(...) method(x, ...)
}

# ============================================================================
# Constructor
# ============================================================================

#' @export
Table <- function(numberOfRows = NULL, numberOfColumns = NULL,
                  columnNames = NULL, .xptr = NULL) {
  
  if (!is.null(.xptr)) {
    ptr <- .xptr
  } else {
    stopifnot(
      "numberOfRows must be specified" = !is.null(numberOfRows),
      "numberOfRows must be positive" = is.numeric(
        numberOfRows) && numberOfRows > 0,
      "Either numberOfColumns or columnNames must be specified" = 
        !is.null(numberOfColumns) || !is.null(columnNames)
    )
    
    if (!is.null(columnNames)) {
      ptr <- .table_create_with_column_names(numberOfRows, columnNames)
    } else {
      ptr <- .table_create(numberOfRows, numberOfColumns)
    }
  }
  
  tbl_mod <- get_module("table_module")
  cpp_obj <- tbl_mod$RTable$new(ptr)
  
  structure(list(
    .cpp = cpp_obj,
    .xptr = ptr
  ), class = c("Table", "PraatObject"))
}

#' @export
as.data.frame.Table <- function(x, ...) x$as_data_frame()

# Factory functions

#' Create a Praat Table
#'
#' Creates a new Table object with specified dimensions.
#'
#' @param numberOfRows Number of rows
#' @param numberOfColumns Number of columns (optional if columnNames provided)
#' @param columnNames Character vector of column names (optional)
#' @return A Table object
#' @seealso \code{\link{Table}} for object methods
#' @examples
#' tbl <- table_create(numberOfRows = 3, columnNames = c("speaker", "f0"))
#' tbl2 <- table_create(numberOfRows = 3, numberOfColumns = 2)
#' @export
table_create <- function(numberOfRows, numberOfColumns = NULL,
  columnNames = NULL) {
  Table(numberOfRows = numberOfRows,
        numberOfColumns = numberOfColumns,
        columnNames = columnNames)
}
