# Create VocalTract from phone

Create VocalTract from phone

## Usage

``` r
vocaltract_create_from_phone(phone)
```

## Arguments

- phone:

  Phone name. Valid phones:

  - Vowels: a, e, i, o, u

  - Special vowels: y1, y2, y3, jery

  - Plosives: p, t, k, x

  - Syllables: pa, ta, ka, pi, ti, ki, pu, tu, ku

## Value

VocalTract object

## Examples

``` r
vt_a <- VocalTract$create_from_phone("a")
vt_i <- VocalTract$create_from_phone("i")

# Compare spectra
spec_a <- vt_a$to_spectrum()
spec_i <- vt_i$to_spectrum()
```
