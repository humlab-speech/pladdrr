# Convert R6 Formant to data frame

S3 method for converting R6 Formant objects to data frames. Delegates to
the R6 \`\$as_data_frame()\` method.

## Usage

``` r
# S3 method for class 'Formant'
as.data.frame(x, row.names = NULL, optional = FALSE, ...)
```

## Arguments

- x:

  A Formant R6 object

- row.names:

  Ignored

- optional:

  Ignored

- ...:

  Additional arguments passed to \`\$as_data_frame()\` (e.g.
  \`max_formants\`)

## Value

A data.table (inherits from data.frame) in long format, one row per
(frame, formant number): columns \`time\`, \`formant\` (1-based formant
number), \`frequency\` (Hz), \`bandwidth\` (Hz). Matches
\`as.data.frame.FormantPath()\`.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.3, sampling_rate = 16000)
formant <- sound$to_formant_burg()
df <- as.data.frame(formant)
head(df)
#> Key: <time, formant>
#>     time formant frequency bandwidth
#>    <num>   <int>     <num>     <num>
#> 1: 0.025       1  187.8023  5.920635
#> 2: 0.025       2  225.4690  5.534837
#> 3: 0.025       3  263.2139  5.143520
#> 4: 0.025       4 4778.6369 11.877056
#> 5: 0.030       1  187.7975  5.880200
#> 6: 0.030       2  225.4687  5.495704
```
