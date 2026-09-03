# Shared parameter documentation for pladdrr functions

Common \`@param\` descriptions used across many functions. Functions
inherit from this topic via \`@inheritParams pladdrr_shared_params
\<param\>\` to avoid duplicating identical documentation.

## Usage

``` r
pladdrr_shared_params(
  sound = NULL,
  from_time = NULL,
  to_time = NULL,
  garnish = NULL,
  sounds = NULL,
  time = NULL,
  sampling_rate = 44100,
  return_r6 = NULL,
  time_step = NULL,
  name = NULL,
  times = NULL,
  from_times = NULL,
  to_times = NULL,
  intensity = NULL,
  time_range = NULL,
  pitch = NULL,
  pitch_floor = 75,
  pitch_ceiling = 600,
  max_candidates = 15,
  unit = NULL,
  row.names = NULL,
  optional = NULL,
  fmin = NULL,
  fmax = NULL,
  x = NULL,
  smooth = NULL,
  bandwidth = NULL,
  tmin = NULL,
  xmin = NULL,
  tmax = NULL,
  xmax = NULL,
  title = NULL,
  tier = NULL,
  textgrid = NULL,
  sound1 = NULL,
  signal_outside = NULL,
  scaling = NULL,
  pointprocess = NULL,
  point_process = NULL,
  n_cores = NULL,
  max_pitch = 600,
  interpolate = NULL,
  from_freq = NULL,
  files = NULL,
  duration = 1,
  cepstrogram = NULL,
  max_formant = NULL,
  ...
)
```

## Arguments

- sound:

  Sound object or external pointer

- from_time:

  Start time in seconds (NULL = from beginning)

- to_time:

  End time in seconds (NULL = to end)

- garnish:

  Logical. Add axis labels and title (default: TRUE)

- sounds:

  List of Sound objects (R6) or external pointers

- time:

  Time in seconds

- sampling_rate:

  Sampling rate in Hz (default: 44100)

- return_r6:

  Logical. Return R6 Pitch objects (TRUE) or raw xptrs (FALSE)

- time_step:

  Numeric. Time step (0 = automatic)

- name:

  Parameter name for error messages

- times:

  Numeric vector of time points (in seconds)

- from_times:

  Numeric vector of start times

- to_times:

  Numeric vector of end times

- intensity:

  An Intensity R6 object

- time_range:

  Optional time range c(start, end)

- pitch:

  Pitch object or external pointer

- pitch_floor:

  Numeric. Pitch floor in Hz (default: 75)

- pitch_ceiling:

  Numeric. Pitch ceiling in Hz (default: 600)

- max_candidates:

  Integer. Max candidates per frame (default: 15)

- unit:

  Unit: "Hz" or "semitones"

- row.names:

  Ignored

- optional:

  Ignored

- fmin:

  Low frequency cutoff (Hz)

- fmax:

  High frequency cutoff (Hz)

- x:

  Object to check

- smooth:

  Smoothing bandwidth (Hz)

- bandwidth:

  Smoothing bandwidth (Hz)

- tmin:

  Start time in seconds

- xmin:

  Start time in seconds

- tmax:

  End time in seconds

- xmax:

  End time in seconds

- title:

  Character. Plot title (default: auto-generated)

- tier:

  Tier number (1-based) or tier name

- textgrid:

  TextGrid object

- sound1:

  First Sound object

- signal_outside:

  Signal outside time domain: 1=zero, 2=similar

- scaling:

  Scaling: 1=integral, 2=sum, 3=normalize, 4=peak_0.99

- pointprocess:

  A PointProcess object

- point_process:

  A PointProcess object

- n_cores:

  Integer. Number of cores (default: auto)

- max_pitch:

  Pitch ceiling in Hz (default: 600)

- interpolate:

  Whether to interpolate

- from_freq:

  Start frequency in Hz (NULL = from 0)

- files:

  Character vector of file paths

- duration:

  Duration in seconds (default: 1.0)

- cepstrogram:

  PowerCepstrogram object

- max_formant:

  Maximum formant frequency (Hz)

- ...:

  Additional arguments (currently unused)
