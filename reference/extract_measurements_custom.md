# Extract Custom Measurements from TextGrid Intervals

Extract acoustic measurements from intervals or points in TextGrid
annotations. This replaces complex Praat scripts that loop over TextGrid
intervals.

## Usage

``` r
extract_measurements_custom(
  sound,
  textgrid,
  tier,
  measures,
  interval_filter = NULL,
  aggregate_by = "interval"
)
```

## Arguments

- sound:

  Sound object or path to sound file

- textgrid:

  TextGrid object or path to TextGrid file

- tier:

  Integer or character, tier number or name

- measures:

  Named list of measurement functions. Each function should accept
  (sound, tmin, tmax) and return a single value or named list

- interval_filter:

  Optional function to filter intervals, receives interval label and
  should return TRUE/FALSE

- aggregate_by:

  Character, how to aggregate: "interval" (default), "label", or "tier"

## Value

Data frame with measurements for each interval/point

## Examples

``` r
# \donttest{
sound <- Sound$create_tone(frequency = 150, duration = 0.6, sampling_rate = 16000)
tg <- textgrid_create(0, 0.6, "phones")
tg$insert_boundary("phones", 0.3)
tg$set_interval_text("phones", 1, "a")
tg$set_interval_text("phones", 2, "e")

measurements <- extract_measurements_custom(
  sound = sound,
  textgrid = tg,
  tier = "phones",
  measures = list(
    mean_f0 = function(snd, t1, t2) snd$to_pitch()$get_mean(0, 0, "hertz"),
    mean_intensity = function(snd, t1, t2) snd$to_intensity()$get_mean(0, 0)
  ),
  interval_filter = function(label) label %in% c("a", "e", "i", "o", "u")
)
# }
```
