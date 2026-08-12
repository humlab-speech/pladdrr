# Extract External Pointer from pladdrr Objects

Unified function to extract external pointers from pladdrr objects.
Handles both function-wrapper and R6 class implementations.

## Usage

``` r
extract_xptr(obj, class_name)
```

## Arguments

- obj:

  Object to extract pointer from (Sound, Pitch, Formant, etc.)

- class_name:

  Expected class name for error messages

## Value

External pointer

## Examples

``` r
sound <- Sound$create_tone(frequency = 220, duration = 0.2, sampling_rate = 8000)
pladdrr:::extract_xptr(sound, "Sound")
#> <pointer: 0x55c8019adf50>
```
