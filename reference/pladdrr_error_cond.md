# Build a classed pladdrr error condition

Build a classed pladdrr error condition

## Usage

``` r
pladdrr_error_cond(klass, routine, param, message, call = sys.call(-1L))
```

## Value

A condition object with class
`c(klass, "pladdrr_error", "error", "condition")` and elements
`message`, `call`, `routine`, `param`.

## Examples

``` r
cond <- pladdrr:::pladdrr_error_cond(
  "pladdrr_input_error", "example_routine", "x", "bad value"
)
conditionMessage(cond)
#> [1] "bad value"
```
