# Praat FormantTier Object

Praat FormantTier object with direct C++ module binding for formant
manipulation.

## Value

A `FormantTier` object with methods for formant frequency and bandwidth
manipulation via time-value points.

## Details

A FormantTier stores formant frequencies and bandwidths at discrete time
points, with interpolation between points. This allows for smooth
formant contours that can be used to filter sounds for vowel
modification or resynthesis.

\## Creating FormantTier Objects

\- \`FormantTier(tmin, tmax)\` - Create empty FormantTier -
\`FormantTier\$from_formant(formant)\` - Convert from Formant object

\## Querying

\- \`\$get_start_time()\` - Start time in seconds -
\`\$get_end_time()\` - End time in seconds - \`\$get_duration()\` -
Duration in seconds - \`\$get_number_of_points()\` - Number of time
points - \`\$get_min_num_formants()\` - Min formants across points -
\`\$get_max_num_formants()\` - Max formants across points -
\`\$get_value_at_time(formant_number, time)\` - Formant frequency (Hz) -
\`\$get_bandwidth_at_time(formant_number, time)\` - Bandwidth (Hz)

\## Transformation

\- \`\$filter_sound(sound, scale=TRUE)\` - Filter sound through
formants - \`\$as_data_frame()\` - Export to data frame -
\`\$save(path)\` - Save to file

## Examples

``` r
# Create from Formant analysis
sound <- Sound$create_tone(frequency = 150, duration = 0.5)
formant <- sound$to_formant_burg()
ft <- FormantTier$from_formant(formant)

# Query formant values
f1 <- ft$get_value_at_time(1, 0.25)  # F1 at 0.25s
f2 <- ft$get_value_at_time(2, 0.25)  # F2 at 0.25s

# Filter a source sound
source <- Sound$create_tone(frequency = 100, duration = 0.5)  # Buzz
vowel <- ft$filter_sound(source)
```
