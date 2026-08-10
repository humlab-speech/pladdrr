# Append two sounds with optional silence

Append two sounds with optional silence

## Usage

``` r
sounds_append(sound1, sound2, silence_duration = 0)
```

## Arguments

- sound1:

  First Sound object

- sound2:

  Second Sound object

- silence_duration:

  Duration of silence to insert between sounds (seconds)

## Value

New Sound object containing sound1, silence, and sound2

## Examples

``` r
s1 <- Sound$create_tone(frequency = 220, duration = 0.2)
s2 <- Sound$create_tone(frequency = 440, duration = 0.2)
combined <- sounds_append(s1, s2, silence_duration = 0.1)
```
