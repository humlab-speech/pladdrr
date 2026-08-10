# Evaluate a string array Praat expression

Evaluate a string array Praat expression

## Usage

``` r
praat_eval_string_array(expression)
```

## Arguments

- expression:

  Character string containing a Praat string array formula

## Value

Character vector

## Examples

``` r
# Create string array
arr <- praat_eval_string_array('{ "hello", "world" }')
```
