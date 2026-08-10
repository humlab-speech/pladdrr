# Build a classed pladdrr warning condition

Build a classed pladdrr warning condition

## Usage

``` r
pladdrr_warning_cond(klass, routine, param, message, call = sys.call(-1L))
```

## Value

A condition object with class
`c(klass, "pladdrr_warning", "warning", "condition")` and elements
`message`, `call`, `routine`, `param`.

## Examples

``` r
cond <- pladdrr:::pladdrr_warning_cond(
  "pladdrr_data_loss", "example_routine", "x", "value out of range"
)
conditionMessage(cond)
#> [1] "value out of range"
```
