# Average multiple Ltas objects

Average multiple Ltas objects

## Usage

``` r
ltas_average(...)
```

## Arguments

- ...:

  Ltas objects to average

## Value

A new Ltas object representing the average

## Examples

``` r
s1 <- Sound$create_tone(frequency = 200, duration = 0.5, sampling_rate =
 16000)
s2 <- Sound$create_tone(frequency = 240, duration = 0.5, sampling_rate =
 16000)
avg <- ltas_average(s1$to_ltas(), s2$to_ltas())
```
