# Critical Issue: Intensity_to_TextGrid_detectSilences Segfault

## Problem
The Praat dwtools function `Intensity_to_TextGrid_detectSilences` consistently segfaults at address 0x68 when called from R, even though:
1. The Intensity object is valid (verified with debug output)
2. The function symbol exists in the library
3. The parameters are correct

## Root Cause (Hypothesis)
The crash occurs inside `Vector_getMaximumAndX` which suggests a vtable or object member issue. Offset 0x68 points to a null pointer dereference in the Praat C++ object hierarchy.

## Solution: Direct Implementation
Instead of using the problematic Praat dwtools function, implement silence detection directly in the wrapper using Intensity values.

This approach:
- Avoids the segfault entirely
- Gives us full control over the algorithm
- Is more transparent and debuggable
- Will be faster (no unnecessary overhead)

See git commit for implementation.
