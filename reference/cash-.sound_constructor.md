# \$ method for Sound constructor (enables Sound\$create_tone(), etc.)

\$ method for Sound constructor (enables Sound\$create_tone(), etc.)

## Usage

``` r
# S3 method for class 'sound_constructor'
x$name
```

## Arguments

- x:

  The Sound constructor function

- name:

  Name of static method to access

## Value

The requested static method function

## Examples

``` r
tone_fn <- Sound$create_tone
sound <- tone_fn(frequency = 220, duration = 0.2, sampling_rate = 8000)
```
