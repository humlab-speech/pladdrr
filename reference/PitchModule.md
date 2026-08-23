# Create a Pitch Object from Module

Creates a Pitch object using the new Rcpp Modules architecture. This is
the constructor function for Pitch objects in pladdrr 2.0.

## Usage

``` r
PitchModule(.ptr = NULL)
```

## Arguments

- .ptr:

  External pointer to a Praat Pitch object (internal use)

## Value

A Pitch object (reference class from Rcpp Module)

## Details

Pitch objects are typically created via \`Sound\$to_pitch()\` rather
than directly. The returned object provides methods for querying pitch
values, statistics, and conversions.

## Methods

- \`get_value_at_time(time, unit, interpolate)\`:

  Get pitch at time

- \`get_mean(from_time, to_time, unit)\`:

  Get mean pitch

- \`get_standard_deviation(from_time, to_time, unit)\`:

  Get pitch SD

- \`get_minimum(from_time, to_time, unit, interpolate)\`:

  Get min pitch

- \`get_maximum(from_time, to_time, unit, interpolate)\`:

  Get max pitch

- \`count_voiced_frames()\`:

  Count voiced frames

- \`as_data_frame(include_strength, include_intensity)\`:

  Convert to data.frame

## Properties

- \`duration\`:

  Duration in seconds

- \`nx\`:

  Number of frames

- \`dx\`:

  Time step between frames

- \`xmin\`, \`xmax\`:

  Start and end times

- \`ceiling\`:

  Pitch ceiling (Hz)

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
pitch <- sound$to_pitch()

# Properties
pitch$duration
#> function (...) 
#> method(x, ...)
#> <bytecode: 0x564d4551b1e8>
#> <environment: 0x564d41d15e78>
pitch$nx
#> function (...) 
#> method(x, ...)
#> <bytecode: 0x564d4551b1e8>
#> <environment: 0x564d4625e0b0>

# Query methods
pitch$get_mean(0, 0, "hertz")  # Mean F0 in Hz
#> [1] 150.0017
pitch$count_voiced_frames()
#> [1] 47

# Export
df <- pitch$as_data_frame(FALSE, FALSE)
```
