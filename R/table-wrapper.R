#' @title Praat Table Object
#' @description
#' Praat Table object with direct C++ module binding for tabular data operations.
#'
#' @details
#' Table objects store tabular data with named columns and support various
#' statistical operations.
#'
#' @return A \code{Table} object with methods for tabular data access and statistics.
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
# Shared Method Dispatch Table
# ============================================================================

.table_methods <- new.env(hash = TRUE, parent = emptyenv())

# Query - Structure
.table_methods$get_number_of_rows <- function(.self) .self$.cpp$get_number_of_rows()
.table_methods$get_number_of_columns <- function(.self) .self$.cpp$get_number_of_columns()
.table_methods$get_column_label <- function(.self, col) .self$.cpp$get_column_label(as.integer(col))
.table_methods$get_column_index <- function(.self, label) .self$.cpp$get_column_index(as.character(label))
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
  col_idx <- if (is.character(column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$get_numeric_value(as.integer(row), col_idx)
}
.table_methods$get_string_value <- function(.self, row, column) {
  col_idx <- if (is.character(column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$get_string_value(as.integer(row), col_idx)
}
.table_methods$set_numeric_value <- function(.self, row, column, value) {
  col_idx <- if (is.character(column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$set_numeric_value(as.integer(row), col_idx, as.numeric(value))
  invisible(.self)
}
.table_methods$set_string_value <- function(.self, row, column, value) {
  col_idx <- if (is.character(column)) .self$.cpp$get_column_index(column) else as.integer(column)
  .self$.cpp$set_string_value(as.integer(row), col_idx, as.character(value))
  invisible(.self)
}

# Statistics
.table_methods$get_mean <- function(.self, column) {
  .table_get_mean(.self$.xptr, as.character(column))
}
.table_methods$get_standard_deviation <- function(.self, column) {
  .table_get_stdev(.self$.xptr, as.character(column))
}

# Export
.table_methods$as_data_frame <- function(.self) .table_to_data_frame(.self$.xptr)
.table_methods$save <- function(.self, path) {
  .table_save(.self$.xptr, as.character(path))
  invisible(.self)
}

# Sort
.table_methods$sort_rows <- function(.self, columns) {
  .table_sort_rows(.self$.xptr, as.character(columns))
  invisible(.self)
}

# Row extraction
.table_methods$extract_rows_where_number <- function(.self, column, which, criterion) {
  if (is.character(column)) {
    column <- .self$.cpp$get_column_index(column)
  }
  tbl_ptr <- .table_extract_rows_where_column_number(
    .self$.xptr, as.integer(column), as.integer(which), as.numeric(criterion)
  )
  Table(.xptr = tbl_ptr)
}

.table_methods$extract_rows_where_string <- function(.self, column, which, criterion) {
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
              .self$.cpp$get_number_of_rows(), .self$.cpp$get_number_of_columns()))
  col_names <- .self$.cpp$get_column_names()
  if (length(col_names) > 0) {
    cat(sprintf("  Columns: %s\n", paste(col_names, collapse = ", ")))
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
      "numberOfRows must be positive" = is.numeric(numberOfRows) && numberOfRows > 0,
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
print.Table <- function(x, ...) x$print()

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
#' @seealso [Table] for object methods
#' @export
table_create <- function(numberOfRows, numberOfColumns = NULL, columnNames = NULL) {
  Table(numberOfRows = numberOfRows,
        numberOfColumns = numberOfColumns,
        columnNames = columnNames)
}
