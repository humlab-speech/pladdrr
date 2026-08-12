# Create example KlattGrid

Creates a demonstration KlattGrid with pre-configured parameters for
testing the synthesizer.

## Usage

``` r
klattgrid_create_example()

# Deprecated: use klattgrid_create_example() instead
```

## Value

KlattGrid example object

## Examples

``` r
kg <- klattgrid_create_example()
sound <- kg$to_sound()
```
