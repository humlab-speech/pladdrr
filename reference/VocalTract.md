# Praat VocalTract Object

Praat VocalTract object with direct C++ module binding for articulatory
synthesis.

## Value

A `VocalTract` object with methods for articulatory tube-model access.

## Details

A VocalTract represents the cross-sectional areas of the vocal tract
from glottis to lips, divided into sections. This can be used for: -
Articulatory synthesis (convert to Spectrum) - Vowel modeling (create
from phone) - Acoustic tube modeling

\## Creating VocalTract Objects

\- \`VocalTract(nx, dx)\` - Create empty vocal tract with nx sections -
\`VocalTract\$create_from_phone(phone)\` - Create from phone name

\## Querying

\- \`\$get_length()\` - Total length in metres -
\`\$get_number_of_sections()\` - Number of sections -
\`\$get_section_length()\` - Section length in metres -
\`\$get_area(section)\` - Area at section (m^2) - \`\$get_areas()\` -
All areas as vector

\## Modification

\- \`\$set_area(section, area)\` - Set area at section -
\`\$set_areas(areas)\` - Set all areas from vector

\## Transformation

\- \`\$to_spectrum(...)\` - Convert to Spectrum for synthesis -
\`\$to_matrix()\` - Convert to Matrix

## Examples

``` r
# Create from phone
vt <- VocalTract$create_from_phone("a")
print(vt)
#> <Praat VocalTract>
#>   Total length: 17.000 cm
#>   Number of sections: 34 
#>   Section length: 5.0 mm
#>   Area range: 0.80 - 8.60 cm^2

# Get areas
areas <- vt$get_areas()

# Convert to spectrum for synthesis
spectrum <- vt$to_spectrum()
```
