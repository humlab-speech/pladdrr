#' @title Praat Table Object
#' @description
#' Praat Table object with direct C++ module binding for tabular data operations.
#'
#' @details
#' Table objects store tabular data with named columns and support various
#' statistical operations.
#'
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
  
  obj <- structure(list(
    .cpp = cpp_obj,
    .xptr = ptr,
    
    # Query - Structure
    get_number_of_rows = function() cpp_obj$get_number_of_rows(),
    get_number_of_columns = function() cpp_obj$get_number_of_columns(),
    get_column_label = function(col) cpp_obj$get_column_label(as.integer(col)),
    get_column_index = function(label) cpp_obj$get_column_index(as.character(label)),
    get_column_names = function() cpp_obj$get_column_names(),
    
    # Modification - Structure
    set_column_label = function(col, label) {
      cpp_obj$set_column_label(as.integer(col), as.character(label))
      invisible(obj)
    },
    append_row = function() {
      cpp_obj$append_row()
      invisible(obj)
    },
    append_column = function(label) {
      cpp_obj$append_column(as.character(label))
      invisible(obj)
    },
    insert_row = function(row) {
      cpp_obj$insert_row(as.integer(row))
      invisible(obj)
    },
    insert_column = function(col, label) {
      cpp_obj$insert_column(as.integer(col), as.character(label))
      invisible(obj)
    },
    
    # Query/Set - Values
    get_numeric_value = function(row, column) {
      col_idx <- if (is.character(column)) cpp_obj$get_column_index(column) else as.integer(column)
      cpp_obj$get_numeric_value(as.integer(row), col_idx)
    },
    get_string_value = function(row, column) {
      col_idx <- if (is.character(column)) cpp_obj$get_column_index(column) else as.integer(column)
      cpp_obj$get_string_value(as.integer(row), col_idx)
    },
    set_numeric_value = function(row, column, value) {
      col_idx <- if (is.character(column)) cpp_obj$get_column_index(column) else as.integer(column)
      cpp_obj$set_numeric_value(as.integer(row), col_idx, as.numeric(value))
      invisible(obj)
    },
    set_string_value = function(row, column, value) {
      col_idx <- if (is.character(column)) cpp_obj$get_column_index(column) else as.integer(column)
      cpp_obj$set_string_value(as.integer(row), col_idx, as.character(value))
      invisible(obj)
    },
    
    # Statistics
    get_mean = function(column) {
      .table_get_mean(ptr, as.character(column))
    },
    get_standard_deviation = function(column) {
      .table_get_stdev(ptr, as.character(column))
    },
    
    # Export
    as_data_frame = function() {
      .table_to_data_frame(ptr)
    },
    save = function(path) {
      .table_save(ptr, as.character(path))
      invisible(obj)
    },
    
    # Utility
    get_xptr = function() ptr,
    
    # Print
    print = function() {
      cat("<Praat Table>\n")
      cat(sprintf("  Dimensions: %d rows × %d columns\n", 
                  cpp_obj$get_number_of_rows(), cpp_obj$get_number_of_columns()))
      col_names <- cpp_obj$get_column_names()
      if (length(col_names) > 0) {
        cat(sprintf("  Columns: %s\n", paste(col_names, collapse = ", ")))
      }
      invisible(obj)
    }
  ), class = c("Table", "PraatObject"))
  
  obj
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
