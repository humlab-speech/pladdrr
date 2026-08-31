# as.data.frame Methods for pladdrr Objects

\`as.data.frame()\` methods for Praat object classes that expose their
data as flat data frames (long format for 2-D matrix-like objects, one
row per sample/point/frame for 1-D tiers and tracks).

## Usage

``` r
# S3 method for class 'Discriminant'
as.data.frame(x, ...)

# S3 method for class 'Electroglottogram'
as.data.frame(x, ...)

# S3 method for class 'FormantModeler'
as.data.frame(x, ...)

# S3 method for class 'PCA'
as.data.frame(x, ...)

# S3 method for class 'PowerCepstrogram'
as.data.frame(x, ...)

# S3 method for class 'BarkSpectrogram'
as.data.frame(x, ...)

# S3 method for class 'Cepstrum'
as.data.frame(x, row.names = NULL, optional = FALSE, power = FALSE, ...)

# S3 method for class 'Cochleagram'
as.data.frame(x, ...)

# S3 method for class 'DTW'
as.data.frame(x, ...)

# S3 method for class 'KlattGrid'
as.data.frame(x, ...)

# S3 method for class 'LPC'
as.data.frame(x, ...)

# S3 method for class 'LongSound'
as.data.frame(x, ...)

# S3 method for class 'Matrix'
as.data.frame(x, ...)

# S3 method for class 'MelSpectrogram'
as.data.frame(x, ...)

# S3 method for class 'VocalTract'
as.data.frame(x, ...)
```

## Arguments

- x:

  A pladdrr R6 object (Discriminant, Electroglottogram, FormantModeler,
  PCA, PowerCepstrogram, BarkSpectrogram, Cepstrum, Cochleagram, DTW,
  KlattGrid, LPC, LongSound, Matrix, MelSpectrogram, or VocalTract).

- ...:

  Passed to methods; currently unused except \`power\` on \`Cepstrum\`.

- row.names:

  Unused (required by the \`as.data.frame()\` generic).

- optional:

  Unused (required by the \`as.data.frame()\` generic).

- power:

  If TRUE, convert to PowerCepstrum and return its nonnegative linear
  power values (column \`power\`) instead of Praat's default raw signed
  cepstrum view. Default FALSE matches \`Cepstrum_drawLinear\`, Praat's
  default "Draw..." command. Note: this returns linear power, not dB —
  \`autoplot()\`/\`autolayer()\` convert to dB (\`10 \* log10(power)\`)
  for display only; that conversion is not applied here.

## Value

A data.frame. Column names vary by class; see each class's
`$as_data_frame()` method or the corresponding \`autoplot.\*\` method
for the exact columns used.

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate =
 16000)
cepstrum <- sound$to_cepstrum()
df <- as.data.frame(cepstrum)
head(df)
#>   quefrency       value
#> 1 0.0000000 -428636.464
#> 2 0.0000625   46822.674
#> 3 0.0001250    7756.941
#> 4 0.0001875   15252.597
#> 5 0.0002500    3524.146
#> 6 0.0003125    8754.908
```
