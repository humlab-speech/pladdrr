# Convert R6 Sound to data frame

S3 method for converting R6 Sound objects to data frames. Delegates to
the R6 \`\$as_data_frame()\` method.

## Usage

``` r
# S3 method for class 'Sound'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A Sound R6 object

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Additional arguments passed to the underlying function or ignored.

## Value

A data.table (inherits from data.frame) with time, channel, and value
columns

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.1, sampling_rate =
 8000)
df <- as.data.frame(sound)
head(df)
#> Key: <time, channel>
#>         time channel     value
#>        <num>   <int>     <num>
#> 1: 0.0000625       1 0.0854235
#> 2: 0.0001875       1 0.2537265
#> 3: 0.0003125       1 0.4144731
#> 4: 0.0004375       1 0.5628762
#> 5: 0.0005625       1 0.6945161
#> 6: 0.0006875       1 0.8054724
```
