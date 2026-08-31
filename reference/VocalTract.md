# VocalTract

Praat VocalTract object: the cross-sectional areas of the vocal tract,
from glottis to lips, divided into sections.

## Arguments

- nx:

  Number of sections. Default 17.

- dx:

  Section length in metres. Default 0.01.

- .xptr:

  Not for direct use. External pointer to the underlying C++ VocalTract
  object; set internally when a method returns a new VocalTract.

## Value

A `VocalTract` object with methods for articulatory tube-model access.

## Details

Used for articulatory synthesis (convert to a Spectrum), vowel modeling
(create from a phone), and acoustic tube modeling.

## Usage


    VocalTract(nx, dx) # create an empty vocal tract with nx sections
    VocalTract$create_from_phone(phone)      # create from a phone name

## Query methods

- `get_length()` - total length in metres

- `get_number_of_sections()` - number of sections

- `get_section_length()` - section length in metres

- `get_area(section)` - area at a section (m^2)

- `get_areas()` - all areas as a vector

## Modification

- `set_area(section, area)` - set the area at a section

- `set_areas(areas)` - set all areas from a vector

## Transformation

- `to_spectrum(...)` - convert to a Spectrum for synthesis

- `to_matrix()` - convert to a Matrix

## See also

\[Spectrum\], \[Matrix\]

## Examples

``` r
vt <- VocalTract$create_from_phone("a")
print(vt)
#> <Praat VocalTract>
#>   Total length: 17.000 cm
#>   Number of sections: 34 
#>   Section length: 5.0 mm
#>   Area range: 0.80 - 8.60 cm^2

areas <- vt$get_areas()

spectrum <- vt$to_spectrum()
```
