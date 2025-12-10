# Pitch Detection Bug Investigation (2025-12-10)

## Problem Report

Tremor analysis revealed pladdrr 1.2.0 produces different pitch detection results than Praat/Parselmouth:

- **Frames 4-9**: pladdrr detects F0 (120-137 Hz), Praat marks as unvoiced ❌
- **Result**: Wrong tremor frequency (4.999 Hz vs 1.736 Hz, 188% error)

## Investigation

### 1. Function Used ✅ CORRECT

**pladdrr**: Uses `Sound_to_Pitch_rawCc()` 
**Praat menu "To Pitch (cc)"**: Also uses `Sound_to_Pitch_rawCc()`

✅ Correct Praat function is being called

### 2. Default Parameters Comparison

**Praat defaults (from praat_Sound.cpp)**:
```
timeStep: 0.0 (auto)
pitchFloor: 75.0
pitchCeiling: 600.0
maximumNumberOfCandidates: 15
veryAccurate: false
silenceThreshold: 0.03
voicingThreshold: 0.45
octaveCost: 0.01
octaveJumpCost: 0.35
voicedUnvoicedCost: 0.14
```

**pladdrr defaults (R/sound-r6-new.R:291-301)**:
```
time_step: 0.0
pitch_floor: 75.0
pitch_ceiling: 600.0
max_candidates: 15
very_accurate: FALSE
silence_threshold: 0.03
voicing_threshold: 0.45
octave_cost: 0.01
octave_jump_cost: 0.35
voiced_unvoiced_cost: 0.14
```

✅ All defaults match Praat exactly

### 3. Potential Issues to Check

#### A. Parameter Order Mismatch?
