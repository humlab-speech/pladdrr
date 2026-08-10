# Extract Measurements from Sound and TextGrid Pairs

High-level function to extract acoustic measurements aligned with
TextGrid intervals. Automates the common Praat workflow of measuring
formants/pitch at interval midpoints.

## Usage

``` r
extract_measurements(
  sound,
  textgrid,
  tier = 1,
  measurements = c("pitch", "formants", "intensity"),
  time_point = c("midpoint", "start", "end", "mean"),
  pitch_params = list(time_step = 0.01, pitch_floor = 75, pitch_ceiling = 600),
  formant_params = list(time_step = 0.01, max_formants = 5, max_frequency = 5500,
    window_length = 0.025, pre_emphasis = 50),
  intensity_params = list(min_pitch = 100, time_step = 0, subtract_mean = TRUE)
)
```

## Arguments

- sound:

  Sound object or file path.

- textgrid:

  TextGrid object or file path.

- tier:

  Integer. Tier number to use for segmentation.

- measurements:

  Character vector. Measurements to extract: "pitch", "formants",
  "intensity", etc.

- time_point:

  Character. Where to measure: "midpoint" (default), "start", "end", or
  "mean".

- pitch_params:

  List. Parameters for pitch extraction (time_step, pitch_floor,
  pitch_ceiling).

- formant_params:

  List. Parameters for formant extraction (max_formants, max_frequency,
  etc.).

- intensity_params:

  List. Parameters for intensity extraction.

## Value

Data frame with one row per interval, columns for label and requested
measurements.

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
tg <- textgrid_create(0, 0.6, "phones")
tg$insert_boundary("phones", 0.3)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "e")

results <- extract_measurements(
  sound = sound,
  textgrid = tg,
  tier = 1,
  measurements = c("pitch", "formants"),
  time_point = "midpoint"
)
#> Warning: [pladdrr_data_loss:formant_get_multiple_formants_at_times:-] 4 of 10 queried formant values were undefined (NA returned)
```
