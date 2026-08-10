# Convert R6 Pitch to data frame

S3 method for converting R6 Pitch objects to data frames. Delegates to
the R6 \`\$as_data_frame()\` method.

## Usage

``` r
# S3 method for class 'Pitch'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'PointProcess'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'TextGrid'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'MFCC'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)

# S3 method for class 'LFCC'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An LFCC R6 object

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Additional arguments (ignored)

## Value

A data.table (inherits from data.frame) with pitch measurements

## Functions

- `as.data.frame(PointProcess)`: Convert PointProcess to data.frame

- `as.data.frame(TextGrid)`: Convert TextGrid to data.frame

- `as.data.frame(MFCC)`: Convert MFCC to data.frame

- `as.data.frame(LFCC)`: Convert LFCC to data.frame

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.3, sampling_rate = 16000)
pitch <- sound$to_pitch()
df <- as.data.frame(pitch)
head(df)
#> Key: <time>
#>     time frequency voiced
#>    <num>     <num> <lgcl>
#> 1:  0.02  150.0017   TRUE
#> 2:  0.03  150.0017   TRUE
#> 3:  0.04  150.0017   TRUE
#> 4:  0.05  150.0017   TRUE
#> 5:  0.06  150.0017   TRUE
#> 6:  0.07  150.0017   TRUE
```
