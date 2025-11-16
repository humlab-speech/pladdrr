#!/bin/bash
# Quick Reference: Continue Building Speaker Package

cd /Users/frkkan96/Documents/src/speaker

echo "=== Speaker Package Build Commands ==="
echo ""

# 1. Get current missing symbol
echo "1. Check latest missing symbol:"
echo "   grep 'symbol not found' final_install.log | tail -1 | c++filt"
echo ""

# 2. Add stub function
echo "2. Add stub to appropriate file:"
echo "   - Graphics functions → src/graphics_stubs_comprehensive.cpp"
echo "   - UiForm/Demo functions → src/uiform_stubs.cpp"
echo "   - praat_* functions → src/praat_stubs.cpp"
echo "   - File I/O → src/sound_fileio_stub.cpp"
echo "   - Numerical → src/num_stubs.cpp or src/num2_stubs.cpp"
echo ""

# 3. Build and install
echo "3. Build and install:"
echo "   R CMD build --no-build-vignettes ."
echo "   rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-speaker"
echo "   R CMD INSTALL speaker_0.4.1.tar.gz 2>&1 | tee final_install.log"
echo ""

# 4. Check if installed
echo "4. Check if installed:"
echo "   R -q -e \"library(speaker); packageVersion('speaker')\""
echo ""

# 5. Test functionality
echo "5. Test basic functionality:"
cat << 'EOF'
   R -q -e "
   library(speaker)
   sound <- Sound$new_from_values(sin(1:1000), 44100)
   pitch <- sound$to_pitch()
   cat('Mean F0:', pitch$get_mean(), '\n')
   "
EOF
echo ""

echo "=== Stub Function Templates ==="
echo ""
echo "For void functions:"
echo "void FunctionName (params...) {"
echo "    // No-op stub for NO_GUI build"
echo "}"
echo ""
echo "For query functions:"
echo "ReturnType FunctionName (params...) {"
echo "    return DefaultValue;  // 0, 0.0, false, nullptr, etc."
echo "}"
echo ""
echo "For functions that should error:"
echo "ReturnType FunctionName (params...) {"
echo "    Melder_throw (U\"FunctionName not available in library mode.\");"
echo "}"
echo ""

echo "=== Current Status ==="
echo "Compilation: ✅ 100% SUCCESS"
echo "Linking: ✅ 100% SUCCESS"
echo "Loading: ⚠️  IN PROGRESS (~95% complete)"
echo "Estimated remaining: 5-10 symbols"
echo ""

echo "=== Documentation ==="
echo "- FINAL_SESSION_REPORT.md - Complete status"
echo "- BUILD_FINAL_STATUS.md - Technical details"
echo "- POTENTIAL_MISSING_STUBS.md - Function reference"
echo ""

echo "=== Last Known Missing Symbol ==="
if [ -f final_install.log ]; then
    symbol=$(grep "symbol not found" final_install.log | tail -1 | sed 's/.*flat namespace .//; s/.$//')
    if [ -n "$symbol" ]; then
        echo "Symbol: $symbol"
        echo "Demangled:"
        echo "$symbol" | c++filt
    else
        echo "No symbol found - check if package installed!"
    fi
else
    echo "No install log found - run install first"
fi
