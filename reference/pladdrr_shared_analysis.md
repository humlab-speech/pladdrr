# Shared parameter docs for analysis defaults (batch/parallel wrappers)

Shared parameter docs for analysis defaults (batch/parallel wrappers)

## Usage

``` r
pladdrr_shared_analysis()
```

## Arguments

- time_step:

  Numeric. Time step in seconds (default: 0.005)

- minimum_pitch:

  Numeric. Minimum pitch for analysis (default: 100)

- data:

  Numeric matrix where rows are observations and columns are variables

- max_frequency:

  Numeric. Maximum frequency in Hz (default: 5000)

- pitch_floor:

  Numeric. Minimum pitch in Hz (default: 75)

- pitch_ceiling:

  Numeric. Maximum pitch in Hz (default: 600)

- channel:

  Channel number (1-based, default 1)

- silence_threshold:

  Silence threshold

- max_formants:

  Maximum number of formants

- start_time:

  Start time in seconds (default: 0.0)

- numberOfRows:

  Number of rows
