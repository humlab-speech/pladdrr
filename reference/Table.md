# Praat Table Object

Praat Table object with direct C++ module binding for tabular data
operations.

## Arguments

- numberOfRows:

  Number of rows. Required unless `.xptr` is given.

- numberOfColumns:

  Number of columns. Required unless `columnNames` or `.xptr` is given.

- columnNames:

  Character vector of column names, used instead of `numberOfColumns` to
  name columns as they are created.

- .xptr:

  Not for direct use. External pointer to the underlying C++ Table
  object; set internally when a method returns a new Table.

## Value

A `Table` object with methods for tabular data access and statistics.

## Details

Table objects store tabular data with named columns and support various
statistical operations.

## Examples

``` r
tbl <- Table(numberOfRows = 3, columnNames = c("word", "duration"))
tbl$set_string_value(1, "word", "cat")
tbl$set_numeric_value(1, "duration", 0.42)
tbl$get_number_of_rows()
#> [1] 3
tbl$get_string_value(1, "word")
#> [1] "cat"
tbl$get_numeric_value(1, "duration")
#> [1] 0.42
```
