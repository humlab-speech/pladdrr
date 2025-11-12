# Sensors Functionality Implementation Plan

**Date**: 2025-11-12  
**Target**: EGG and EMA support in speaker package

## Implementation Phases

### Phase 1: Prerequisites (AmplitudeTier)
**Status**: To implement  
**Priority**: HIGH (required for EGG)

AmplitudeTier is a RealTier subclass representing sound pressure in Pascals.

#### Files to Create:
1. `R/amplitudetier-r6.R` - R6 class
2. `src/amplitudetier_wrappers.cpp` - Rcpp wrappers

#### Functions:
- `AmplitudeTier_create(tmin, tmax)`
- `PointProcess_Sound_to_AmplitudeTier_point()` - Extract amplitudes at points
- `PointProcess_Sound_to_AmplitudeTier_period()` - Extract period amplitudes
- `AmplitudeTier_to_IntensityTier()` - Convert to dB
- `IntensityTier_to_AmplitudeTier()` - Convert from dB
- `Sound_AmplitudeTier_multiply()` - Apply amplitude envelope
- Shimmer measurements (local, apq3, apq5, apq11, dda)

### Phase 2: Electroglottogram
**Status**: To implement  
**Priority**: HIGH (main sensor type)

Electroglottogram inherits from Sound, so we can reuse existing Sound infrastructure.

#### Files to Create:
1. `R/electroglottogram-r6.R` - R6 class
2. `src/electroglottogram_wrappers.cpp` - Rcpp wrappers

#### Core Functions:
- `sound_extract_electroglottogram(sound, channel, invert)` - Extract EGG from channel
- `electroglottogram_high_pass_filter(egg, from_freq, smoothing)` - Remove DC drift
- `electroglottogram_derivative(egg, lowpass_freq, smoothing, peak_amp)` - Get DEGG
- `electroglottogram_first_central_difference(egg, peak_amp)` - Simple DEGG
- `electroglottogram_to_sound(egg)` - Convert to Sound

#### Analysis Functions:
- `electroglottogram_to_amplitude_tier_levels(egg, pitch_floor, pitch_ceiling, closing_threshold)`
  - Returns list with: levels, peaks, valleys
- `electroglottogram_to_textgrid_closed_glottis(egg, pitch_floor, pitch_ceiling, closing_threshold, peak_threshold)`
  - Returns TextGrid with closed glottis intervals
- `electroglottogram_to_texttier_closed_glottis(egg, pitch_floor, pitch_ceiling, closing_threshold, silence_threshold, method)`
  - Returns TextTier with points

#### Parameters:
- `pitch_floor`: Minimum pitch (default 75 Hz)
- `pitch_ceiling`: Maximum pitch (default 500 Hz)
- `closing_threshold`: Fraction of peak-valley range (default 0.3)
- `method`: "peaks" or "derivative"

### Phase 3: EMA (Optional)
**Status**: Future  
**Priority**: MEDIUM (specialized research)

#### Files to Create:
1. `R/ema-r6.R` - R6 class
2. `src/ema_wrappers.cpp` - Rcpp wrappers
3. `src/ema_io.cpp` - Carstens file format support

#### Functions:
- `ema_read_carstens(filename)` - Read .pos files
- `ema_create(tmin, tmax, n_sensors, n_frames, dt, x1)`
- Accessor methods for sensor data (x, y, z, phi, theta)
- Plotting functions for trajectories

### Phase 4: EMArawData (Optional)
**Status**: Future  
**Priority**: LOW (niche use case)

#### Functions:
- `emarawdata_read_carstens(filename)` - Read .amp files
- Accessor methods for transmitter amplitudes

## R6 Class Structures

### AmplitudeTier
```r
AmplitudeTier <- R6::R6Class(
  "AmplitudeTier",
  inherit = PraatObject,  # Or RealTier if we create it
  public = list(
    initialize = function(.xptr) {...},
    add_point = function(time, value) {...},
    get_value_at_time = function(time) {...},
    to_intensity_tier = function(threshold_db = -200) {...},
    get_shimmer_local = function(...) {...},
    # etc.
  )
)
```

### Electroglottogram
```r
Electroglottogram <- R6::R6Class(
  "Electroglottogram",
  inherit = Sound,  # IS-A Sound
  public = list(
    initialize = function(.xptr) {...},
    to_textgrid_closed_glottis = function(
      pitch_floor = 75,
      pitch_ceiling = 500,
      closing_threshold = 0.3,
      peak_threshold = 0.05
    ) {...},
    to_amplitude_tier_levels = function(
      pitch_floor = 75,
      pitch_ceiling = 500,
      closing_threshold = 0.3
    ) {...},
    derivative = function(lowpass_freq = 5000, smoothing = 100, peak_amp = 0) {...},
    high_pass_filter = function(from_freq = 100, smoothing = 100) {...},
    to_sound = function() {...}
  )
)
```

### EMA
```r
EMA <- R6::R6Class(
  "EMA",
  inherit = PraatObject,
  public = list(
    initialize = function(.xptr) {...},
    get_sensor_data = function(sensor_num) {...},
    get_frame = function(frame_num) {...},
    # Plotting methods
  ),
  active = list(
    n_sensors = function() {...},
    n_frames = function() {...},
    sensor_names = function() {...}
  )
)
```

## Implementation Order

1. **AmplitudeTier** (1-2 hours)
   - Create R6 class
   - Implement Rcpp wrappers
   - Add basic tests
   
2. **Electroglottogram** (2-3 hours)
   - Create R6 class (inherits Sound)
   - Implement extraction from Sound
   - Implement closed glottis detection
   - Implement DEGG calculation
   - Add filtering functions
   - Create tests and examples

3. **Documentation** (1 hour)
   - Roxygen documentation
   - Vignette on EGG analysis
   - Example EGG data file

4. **EMA** (if needed, 3-4 hours)
   - Create R6 class
   - Implement file I/O for Carstens format
   - Add visualization
   - Create tests

## Test Data Needs

### For Electroglottogram:
- EGG signal (can extract from channel of example audio)
- Or: synthetic EGG signal
- Expected closed glottis intervals
- Expected DEGG peaks

### For EMA:
- Carstens .pos file (if available)
- Or: mock EMA data

## Documentation Topics

1. **EGG Theory**:
   - What is measured
   - Interpretation of waveform
   - Closed quotient vs. open quotient
   - Voice quality assessment

2. **DEGG (Derivative EGG)**:
   - Why take derivative
   - Peak interpretation (glottal closure instant)
   - Applications in voice research

3. **Parameter Selection**:
   - Choosing pitch range
   - Closing threshold tuning
   - When to use peaks vs. derivative method

4. **Use Cases**:
   - Voice quality studies
   - Phonation type analysis
   - Clinical voice assessment
   - Synchronization with acoustic signal

## Testing Strategy

### AmplitudeTier Tests:
- Create tier and add points
- Get value at time (interpolation)
- Convert to/from IntensityTier
- Shimmer calculation
- Multiply with Sound

### Electroglottogram Tests:
- Extract from Sound channel
- High-pass filtering
- Derivative calculation
- Closed glottis detection
- Parameter variations

## Next Steps

1. ✅ Assessment complete
2. ⬜ Implement AmplitudeTier
3. ⬜ Implement Electroglottogram
4. ⬜ Create examples and tests
5. ⬜ Document in vignette
6. ⬜ Consider EMA based on user feedback
