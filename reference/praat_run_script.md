# Execute a Praat script

Executes a Praat script with automatic interpreter initialization.
Objects created during script execution remain in Praat's internal
object list.

## Usage

``` r
praat_run_script(script)
```

## Arguments

- script:

  Character string containing Praat script code

## Value

Invisibly returns NULL

## Examples

``` r
# Create a sound and extract pitch
praat_run_script('
  Create Sound from formula: "test", 1, 0, 1, 44100, "0.5 * sin(2*pi*440*x)"
  pitch = To Pitch: 0.0, 75, 600
')
```
