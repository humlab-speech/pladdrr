# Create Built-in Interval Predicates

Returns external pointers to pre-compiled predicates for common
filtering tasks. Use these instead of compiling your own for simple
cases.

## Usage

``` r
get_interval_predicate(type, threshold = 0)
```

## Arguments

- type:

  Predicate type: "non_empty", "min_duration", "max_duration"

- threshold:

  Numeric threshold (for duration predicates)

## Value

External pointer to predicate function

## Details

Available predicates: - "non_empty": Matches intervals with non-empty
labels (label\[0\] != '\0') - "min_duration": Matches intervals with
duration \>= threshold - "max_duration": Matches intervals with duration
\<= threshold

## Examples

``` r
tg <- TextGrid$create(0, 1, "words")
tg$insert_boundary(1, 0.5)
tg$set_interval_text(1, 2, "hello")

# Get all non-empty intervals
pred <- get_interval_predicate("non_empty")
result <- textgrid_filter_xptr(tg$.xptr, 1, pred)

# Get intervals longer than 100ms
pred <- get_interval_predicate("min_duration", 0.1)
result <- textgrid_filter_xptr(tg$.xptr, 1, pred)
```
