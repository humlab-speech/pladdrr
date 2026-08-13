# Create a Praat Table

Creates a new Table object with specified dimensions.

## Usage

``` r
table_create(numberOfRows, numberOfColumns = NULL, columnNames = NULL)
```

## Arguments

- numberOfRows:

  Number of rows

- numberOfColumns:

  Number of columns (optional if columnNames provided)

- columnNames:

  Character vector of column names (optional)

## Value

A Table object

## See also

[`Table`](https://humlab-speech.github.io/pladdrr/reference/Table.md)
for object methods

## Examples

``` r
tbl <- table_create(numberOfRows = 3, columnNames = c("speaker", "f0"))
tbl2 <- table_create(numberOfRows = 3, numberOfColumns = 2)
```
