#' Table Class
#'
#' R6 class representing a Praat Table object. Table objects store tabular data
#' with named columns and support various statistical operations.
#'
#' @examples
#' \dontrun{
#' # Create a table with column names
#' tbl <- Table$new(numberOfRows = 10, columnNames = c("time", "f0", "intensity"))
#' 
#' # Set values
#' tbl$set_numeric_value(row = 1, column = "time", value = 0.5)
#' tbl$set_numeric_value(row = 1, column = "f0", value = 120.5)
#' 
#' # Get values
#' time_val <- tbl$get_numeric_value(row = 1, column = "time")
#' 
#' # Get column statistics
#' mean_f0 <- tbl$get_mean(column = "f0")
#' sd_f0 <- tbl$get_standard_deviation(column = "f0")
#' 
#' # Export to R data frame
#' df <- tbl$as_data_frame()
#' }
#'
#' @export
Table <- R6::R6Class("Table",
  inherit = PraatObject,
  
  public = list(
    #' @description
    #' Create a new Table object
    #' @param numberOfRows Integer number of rows
    #' @param numberOfColumns Integer number of columns (if columnNames not provided)
    #' @param columnNames Character vector of column names (optional)
    #' @param .xptr Internal: external pointer to Praat Table object
    #' @return A new Table object
    initialize = function(numberOfRows = NULL, numberOfColumns = NULL, 
                         columnNames = NULL, .xptr = NULL) {
      if (!is.null(.xptr)) {
        stopifnot(".xptr must be an external pointer" = inherits(.xptr, "externalptr"))
        private$ptr <- .xptr
      } else {
        stopifnot(
          "numberOfRows must be specified" = !is.null(numberOfRows),
          "numberOfRows must be positive" = is.numeric(numberOfRows) && numberOfRows > 0,
          "Either numberOfColumns or columnNames must be specified" = 
            !is.null(numberOfColumns) || !is.null(columnNames)
        )
        
        if (!is.null(columnNames)) {
          private$ptr <- .table_create_with_column_names(numberOfRows, columnNames)
        } else if (!is.null(numberOfColumns)) {
          private$ptr <- .table_create(numberOfRows, numberOfColumns)
        }
      }
    },
    
    # ========================================================================
    # Query methods - Structure
    # ========================================================================
    
    #' @description Get the number of rows
    #' @return Integer number of rows
    get_number_of_rows = function() {
      .table_get_number_of_rows(private$ptr)
    },
    
    #' @description Get the number of columns
    #' @return Integer number of columns
    get_number_of_columns = function() {
      .table_get_number_of_columns(private$ptr)
    },
    
    #' @description Get column label
    #' @param columnNumber Integer column number (1-based)
    #' @return Character string column label
    get_column_label = function(columnNumber) {
      .table_get_column_label(private$ptr, columnNumber)
    },
    
    #' @description Get column index from name
    #' @param columnName Character string column name
    #' @return Integer column index (0 if not found)
    get_column_index = function(columnName) {
      .table_get_column_index(private$ptr, columnName)
    },
    
    #' @description Get all column names
    #' @return Character vector of column names
    get_column_names = function() {
      .table_get_column_names(private$ptr)
    },
    
    # ========================================================================
    # Query methods - Cell access
    # ========================================================================
    
    #' @description Get numeric value from cell
    #' @param rowNumber Integer row number (1-based)
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric value
    get_numeric_value = function(rowNumber, columnNumber) {
      .table_get_numeric_value(private$ptr, rowNumber, columnNumber)
    },
    
    #' @description Get string value from cell
    #' @param rowNumber Integer row number (1-based)
    #' @param columnNumber Integer column number (1-based)
    #' @return Character string value
    get_string_value = function(rowNumber, columnNumber) {
      .table_get_string_value(private$ptr, rowNumber, columnNumber)
    },
    
    # ========================================================================
    # Modification methods
    # ========================================================================
    
    #' @description Set column label
    #' @param columnNumber Integer column number (1-based)
    #' @param label Character string new label
    set_column_label = function(columnNumber, label) {
      invisible(.table_set_column_label(private$ptr, columnNumber, label))
    },
    
    #' @description Set numeric value in cell
    #' @param rowNumber Integer row number (1-based)
    #' @param columnNumber Integer column number (1-based)
    #' @param value Numeric value
    set_numeric_value = function(rowNumber, columnNumber, value) {
      invisible(.table_set_numeric_value(private$ptr, rowNumber, columnNumber, value))
    },
    
    #' @description Set string value in cell
    #' @param rowNumber Integer row number (1-based)
    #' @param columnNumber Integer column number (1-based)
    #' @param value Character string value
    set_string_value = function(rowNumber, columnNumber, value) {
      invisible(.table_set_string_value(private$ptr, rowNumber, columnNumber, value))
    },
    
    #' @description Append a new row
    append_row = function() {
      invisible(.table_append_row(private$ptr))
    },
    
    #' @description Append a new column
    #' @param columnName Character string column name
    append_column = function(columnName) {
      invisible(.table_append_column(private$ptr, columnName))
    },
    
    #' @description Remove a row
    #' @param rowNumber Integer row number (1-based)
    remove_row = function(rowNumber) {
      invisible(.table_remove_row(private$ptr, rowNumber))
    },
    
    #' @description Remove a column
    #' @param columnNumber Integer column number (1-based)
    remove_column = function(columnNumber) {
      invisible(.table_remove_column(private$ptr, columnNumber))
    },
    
    #' @description Insert a row
    #' @param rowPosition Integer position (1-based)
    insert_row = function(rowPosition) {
      invisible(.table_insert_row(private$ptr, rowPosition))
    },
    
    #' @description Insert a column
    #' @param columnPosition Integer position (1-based)
    #' @param columnName Character string column name
    insert_column = function(columnPosition, columnName) {
      invisible(.table_insert_column(private$ptr, columnPosition, columnName))
    },
    
    # ========================================================================
    # Statistical methods
    # ========================================================================
    
    #' @description Get mean of column
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric mean value
    get_mean = function(columnNumber) {
      .table_get_mean(private$ptr, columnNumber)
    },
    
    #' @description Get standard deviation of column
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric standard deviation
    get_stdev = function(columnNumber) {
      .table_get_stdev(private$ptr, columnNumber)
    },
    
    #' @description Get minimum value of column
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric minimum value
    get_minimum = function(columnNumber) {
      .table_get_minimum(private$ptr, columnNumber)
    },
    
    #' @description Get maximum value of column
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric maximum value
    get_maximum = function(columnNumber) {
      .table_get_maximum(private$ptr, columnNumber)
    },
    
    #' @description Get sum of column
    #' @param columnNumber Integer column number (1-based)
    #' @return Numeric sum
    get_sum = function(columnNumber) {
      .table_get_sum(private$ptr, columnNumber)
    },
    
    #' @description Get quantile of column
    #' @param columnNumber Integer column number (1-based)
    #' @param quantile Numeric quantile value (0-1)
    #' @return Numeric quantile value
    get_quantile = function(columnNumber, quantile) {
      .table_get_quantile(private$ptr, columnNumber, quantile)
    },
    
    # ========================================================================
    # Conversion methods
    # ========================================================================
    
    #' @description Convert table to R matrix
    #' @return Numeric matrix
    to_matrix = function() {
      .table_to_matrix(private$ptr)
    },
    
    #' @description Convert table to R data frame
    #' @return Data frame
    to_data_frame = function() {
      mat <- self$to_matrix()
      df <- as.data.frame(mat)
      names(df) <- self$get_column_names()
      df
    }
  )
)

#' Create a Table object
#'
#' @param numberOfRows Integer number of rows
#' @param numberOfColumns Integer number of columns (if columnNames not provided)
#' @param columnNames Character vector of column names (optional)
#' @return A Table object
#' @export
praat_table <- function(numberOfRows, numberOfColumns = NULL, columnNames = NULL) {
  Table$new(numberOfRows = numberOfRows, 
            numberOfColumns = numberOfColumns,
            columnNames = columnNames)
}
