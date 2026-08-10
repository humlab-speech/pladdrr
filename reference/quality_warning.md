# Issue a quality warning

Issues a warning about potentially poor analysis quality (Constitution
Principle I: User should be warned about quality issues)

## Usage

``` r
quality_warning(message)
```

## Arguments

- message:

  Warning message

## Value

The result of the underlying
[`warning()`](https://rdrr.io/r/base/warning.html) call, invisibly;
called for the side effect of issuing a warning.

## Examples

``` r
withCallingHandlers(
  pladdrr:::quality_warning("example quality issue"),
  warning = function(w) {
    message("caught: ", conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
#> caught: example quality issue
```
