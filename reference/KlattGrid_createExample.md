# Create example KlattGrid

Creates a demonstration KlattGrid with pre-configured parameters for
testing the synthesizer.

## Usage

``` r
KlattGrid_createExample()
```

## Value

KlattGrid example object

## Examples

``` r
kg <- KlattGrid_createExample()
sound <- kg$to_sound()
```
