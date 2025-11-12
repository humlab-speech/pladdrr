# Praat Sensors Functionality Assessment

**Date**: 2025-11-12  
**Focus**: EGG and EMA sensor analysis integration

## Overview

The Praat `sensors` subdirectory provides specialized functionality for analyzing physiological signals used in speech research:

1. **Electroglottogram (EGG)**: Measures vocal fold contact area during phonation
2. **EMA (Electromagnetic Articulography)**: Tracks articulatory movements using sensors
3. **EMArawData**: Raw amplitude data from EMA transmitters

## Object Hierarchies

### Electroglottogram
- **Inherits from**: Sound
- **Purpose**: Specialized Sound object representing vocal fold contact
- **Key characteristics**:
  - Single-channel Sound
  - Can be accompanied by acoustic sound at same sampling rate
  - Represents degree of contact between vibrating vocal folds

### EMA
- **Inherits from**: Sampled
- **Purpose**: 3D position tracking of articulatory sensors over time
- **Data structure**:
  - Multiple sensors (up to 24)
  - Each frame contains per-sensor: x, y, z, phi, theta
  - Time-sampled data
- **File format support**: Carstens EMA 50x .pos files

### EMArawData
- **Inherits from**: Sampled
- **Purpose**: Raw transmitter amplitude data for EMA
- **Data structure**:
  - Multiple sensors with multiple transmitters per sensor
  - Amplitude values per transmitter per frame
  - Calibration matrix
- **File format support**: Carstens EMA 50x .amp files

## Key Functionality

### Electroglottogram Functions

#### Creation & Extraction
- `Electroglottogram_create()`: Create from parameters
- `Sound_extractElectroglottogram()`: Extract from Sound channel with optional inversion

#### Analysis
- `Electroglottogram_to_AmplitudeTier_levels()`: Extract peak/valley levels
- `Electroglottogram_to_TextGrid_closedGlottis()`: Detect closed glottis intervals
- `Electroglottogram_to_TextTier_closedGlottis()`: Alternative closed interval detection

#### Signal Processing
- `Electroglottogram_derivative()`: Real derivative calculation
- `Electroglottogram_firstCentralDifference()`: Central difference approximation
- `Electroglottogram_highPassFilter()`: Remove DC drift

#### Conversion
- `Electroglottogram_to_Sound()`: Convert back to Sound

#### Parameters
- **Pitch range**: pitchFloor, pitchCeiling (typical: 75-500 Hz)
- **Closing threshold**: Fraction of peak-valley range (typical: 0.3)
- **Methods**: PEAKS or DERIVATIVE for interval detection

### EMA Functions

#### File I/O
- `EMA_readFromCarstensEMA50xPosFile()`: Read Carstens binary format
- `CarstensEMA_processHeader()`: Parse header information

#### Creation
- `EMA_create()`: Create EMA object from parameters

#### Header Processing
- Supports versions 1, 2, 3 of Carstens AG50x format
- Parses: version, header size, number of sensors, sampling frequency

### EMArawData Functions

#### File I/O
- `EMArawData_readFromCarstensEMA50xAmpFile()`: Read Carstens amplitude data

#### Creation
- `EMArawData_create()`: Create from parameters

## Integration with Other Objects

### Sound
- Electroglottogram IS-A Sound (inheritance)
- Can be extracted from multi-channel Sound
- Can be converted back to Sound
- Uses Sound_to_PointProcess for peak detection

### TextGrid
- Output: Closed glottis intervals as TextGrid tiers
- Uses IntervalTier for marking intervals

### AmplitudeTier
- Output: Level tracking (peaks, valleys, closing levels)
- Uses PointProcess_Sound_to_AmplitudeTier

### PointProcess
- Internal: Peak and valley detection
- Uses Sound_to_PointProcess_periodic_peaks

## Use Cases

### EGG Analysis
1. **Voice quality assessment**: Closed quotient, open quotient
2. **Phonation type analysis**: Modal vs. breathy voice
3. **Vocal fold dynamics**: Contact patterns during speech
4. **Synchronization**: Align EGG with acoustic signal

### EMA Analysis
1. **Articulatory kinematics**: Tongue, lip, jaw movements
2. **Coarticulation studies**: Spatial-temporal patterns
3. **Phonetic research**: Vowel/consonant articulation
4. **Clinical assessment**: Speech motor control

## Implementation Priority for `speaker` Package

### Phase 1: Electroglottogram (HIGH PRIORITY)
- Commonly used in voice research
- Relatively simple (inherits from Sound)
- Clear analysis pipeline
- Important for phonation studies

**Recommended functions**:
1. `sound_extract_electroglottogram()` - Extract from channel
2. `electroglottogram_to_textgrid()` - Detect closed intervals
3. `electroglottogram_derivative()` - Get DEGG
4. `electroglottogram_high_pass_filter()` - Remove drift

### Phase 2: EMA (MEDIUM PRIORITY)
- Specialized research tool
- Complex 3D spatial-temporal data
- Requires file format support
- Less common than EGG

**Recommended functions**:
1. `ema_read_carstens()` - Read .pos files
2. `ema_create()` - Create object
3. Accessor methods for sensor data

### Phase 3: EMArawData (LOW PRIORITY)
- Very specialized
- Raw data typically processed into EMA
- Niche use case

## R7 Class Design

### Electroglottogram
```r
Electroglottogram <- new_class(
  "Electroglottogram",
  parent = Sound,  # Inherits from Sound
  properties = list()  # No additional properties
)
```

### EMA
```r
EMA <- new_class(
  "EMA",
  parent = Sampled,
  properties = list(
    sensor_names = class_character,
    sensor_frames = class_list  # List of data frames with x, y, z, phi, theta
  )
)
```

## Dependencies

### Existing speaker Objects
- ✅ Sound (implemented)
- ✅ TextGrid (implemented)
- ⚠️ AmplitudeTier (not yet implemented in R7)
- ⚠️ PointProcess (not yet implemented in R7)

### Required Implementations
- AmplitudeTier should be implemented first
- PointProcess for peak detection

## Enums

### kElectroglottogram_findClosedIntervalMethod
- PEAKS: Use peak-based detection
- DERIVATIVE: Use derivative-based detection

### kElectroglottogram_extract
- ELECTROGLOTTOGRAM: Extract as EGG
- SOUND: Extract as Sound

## Documentation Needs

1. EGG theory and interpretation
2. Closed quotient calculation
3. DEGG (derivative EGG) interpretation
4. Parameter selection guidelines
5. EMA coordinate systems and sensors

## Next Steps

1. Implement AmplitudeTier and PointProcess as prerequisites
2. Create Electroglottogram R7 class (inherits Sound)
3. Implement core EGG analysis functions
4. Add Rcpp wrappers for Praat EGG functions
5. Create examples with real EGG data
6. Document voice quality metrics derivable from EGG
7. Consider EMA implementation based on user demand
