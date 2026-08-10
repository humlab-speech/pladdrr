# Create FormantTier from Formant

Create FormantTier from Formant

## Usage

``` r
formanttier_from_formant(formant)
```

## Arguments

- formant:

  Formant object to convert

## Value

FormantTier object

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.5, sampling_rate = 16000)
formant <- sound$to_formant_burg()
ft <- FormantTier$from_formant(formant)
print(ft)
#> <Praat FormantTier>
#>   Time domain: 0.000 - 0.500 seconds
#>   Number of points: 90 
#>   Formants per point: 4 
```
