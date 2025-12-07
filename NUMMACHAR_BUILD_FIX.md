# NUMmachar Build Fix - 2025-12-07

## Problem
Package built successfully but failed to load with:
```
symbol not found in flat namespace '__Z9NUMmacharv'
```

## Root Cause
`NUMmachar.cpp` was not included in the build system. The file exists at:
- `/src/praat.github.io/dwsys/NUMmachar.cpp`

But was missing from `DWSYS_SRC` in the Makevars configuration.

## Key Discovery
**Makevars is auto-generated from Makevars.in by configure script**

Manual edits to `src/Makevars` were being overwritten during builds. The source file that needed editing was `src/Makevars.in`.

## Solution
Added `NUMmachar.cpp` to DWSYS_SRC in `src/Makevars.in`:

```makefile
DWSYS_SRC = praat.github.io/dwsys/NUMFourier.cpp \
            ...
            praat.github.io/dwsys/NUMstring.cpp \
            praat.github.io/dwsys/NUMmachar.cpp
```

## Build Steps
```bash
cd /Users/frkkan96/Documents/src/pladdrr
rm -rf src/*.o src/*.so src/Makevars
find src/praat.github.io -name "*.o" -delete
./configure
R CMD INSTALL --preclean .
```

## Result
✅ Package compiles successfully
✅ Package installs successfully  
✅ Symbol `__Z9NUMmacharv` now exported in pladdrr.so
✅ Package loads without "symbol not found" error

## Verification
```bash
nm -gU pladdrr.so | grep -i nummachar
# Output: 00000000000f1200 T __Z9NUMmacharv
```

## Next Issue Discovered
⚠️ **New segfault in pitch extraction**

The package now loads, but crashes during pitch analysis:
```
*** caught segfault ***
address 0x20, cause 'invalid permissions'
Traceback:
 1: .sound_to_pitch(private$ptr, time_step, pitch_floor, pitch_ceiling)
 2: snd$to_pitch()
```

Crash occurs in `NUMimproveMaximum()` → `brent()` numerical optimization code.

This is a **separate bug** from the build/linking issue.

## Files Modified
- `src/Makevars.in` - Added NUMmachar.cpp to DWSYS_SRC (line 106)

## Debugging Steps Taken
1. Identified missing symbol via `nm` on .so file
2. Found NUMmachar.cpp exists but wasn't being compiled
3. Attempted to add to Makevars - changes reverted
4. Discovered Makevars.in is the source file
5. Added to Makevars.in and successfully rebuilt
6. Verified symbol export
7. Tested package load - SUCCESS
8. Tested pitch extraction - NEW SEGFAULT

## Next Steps
1. Debug segfault in `brent()` numerical code
2. Check if `NUMmachar()` needs to be called at initialization
3. Verify NUMfpp structure is properly initialized
4. Check pointer arithmetic in `NUMimproveMaximum()`
