# Concatenate Multiple Sounds in Single C++ Call

Concatenates a list of Sound objects at the C++ level, avoiding the O(n)
R→C boundary crossings that occur with \`Reduce(function(a,b)
a\$concatenate(b), sounds)\`.

## Usage

``` r
sound_concatenate_all(sounds, overlap = 0, return_r6 = TRUE)
```

## Arguments

- sounds:

  List of Sound objects (R6) or external pointers

- overlap:

  Numeric. Overlap duration in seconds (default: 0)

- return_r6:

  Logical. Return R6 Sound object (TRUE) or raw xptr (FALSE)

## Value

Sound object (R6 or xptr depending on return_r6)

## Examples

``` r
sound_list <- list(
  Sound$create_tone(frequency = 440, duration = 0.2),
  Sound$create_tone(frequency = 880, duration = 0.2)
)
result <- sound_concatenate_all(sound_list)
```
