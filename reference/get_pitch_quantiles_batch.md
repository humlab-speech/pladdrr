# Get Multiple Pitch Quantiles in Single Call (NEW for VUV Performance)

Extract multiple quantiles (e.g., Q1, Q3) from a Pitch object in a
single C++ call instead of calling \`get_quantile()\` multiple times.
Specifically designed for VUV analysis workflows where adaptive pitch
ranges are calculated from quartiles.

## Usage

``` r
get_pitch_quantiles_batch(
  pitch,
  quantiles,
  from_time = 0,
  to_time = 0,
  unit = "hertz"
)
```

## Arguments

- pitch:

  A Pitch object

- quantiles:

  Numeric vector of quantile values (e.g., c(0.25, 0.75) for Q1 and Q3)

- from_time:

  Start time (0 = beginning of pitch object)

- to_time:

  End time (0 = end of pitch object)

- unit:

  Unit for pitch values: "hertz" (default), "mel", "loghertz",
  "semitones", or "erb"

## Value

Named numeric vector with quantile values (names like "q0.25", "q0.75")

## Performance

Reduces R\<-\>C++ boundary crossings from n separate calls to 1 call.

## Use Case - VUV Analysis

“\`r \# Extract adaptive pitch range for refined pitch analysis
quantiles \<- get_pitch_quantiles_batch(pitch_rough, c(0.25, 0.75))
pitch_refined \<- to_pitch_cc_direct( sound, pitch_floor =
quantiles\["q0.25"\] \* 0.75, pitch_ceiling = quantiles\["q0.75"\] \*
1.5 ) “\`

## Examples

``` r
sound <- Sound$create_tone(frequency = 150, duration = 0.5, sampling_rate =
 16000)
pitch <- sound$to_pitch()

# Get Q1, median, Q3 in one call
quartiles <- get_pitch_quantiles_batch(pitch, c(0.25, 0.5, 0.75))

# Access by name
q1 <- quartiles["q0.25"]
median <- quartiles["q0.5"]
q3 <- quartiles["q0.75"]
```
