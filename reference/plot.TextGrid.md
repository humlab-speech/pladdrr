# Plot TextGrid Annotations

Visualize tier labels and boundaries as a standalone plot.

## Usage

``` r
# S3 method for class 'TextGrid'
plot(x, tier = NULL, from_time = NULL, to_time = NULL, ...)
```

## Arguments

- x:

  A TextGrid object

- tier:

  Integer or character specifying which tier to plot (default: all
  tiers)

- from_time:

  Start time in seconds (NULL = beginning)

- to_time:

  End time in seconds (NULL = end)

## Value

A ggplot2 object

## Examples

``` r
tg <- TextGrid$create(0, 1, "words")
tg$set_interval_text("words", 1, "hello")
plot(tg)

plot(tg, tier = 1)

```
