# Convert R6 Intensity to data frame

S3 method for converting R6 Intensity objects to data frames. Delegates
to the R6 \`\$as_data_frame()\` method.

## Usage

``` r
# S3 method for class 'Intensity'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  An Intensity R6 object

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Additional arguments (ignored)

## Value

A data.table (inherits from data.frame) with time and intensity columns

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
intensity <- sound$to_intensity()
df <- as.data.frame(intensity)
head(df)
#> Key: <time>
#>     time intensity_db
#>    <num>        <num>
#> 1: 0.034     90.88181
#> 2: 0.042     90.88218
#> 3: 0.050     90.88180
#> 4: 0.058     90.88217
#> 5: 0.066     90.88181
#> 6: 0.074     90.88216
```
