#!/bin/bash
# Auto-fix missing symbols script

cd /Users/frkkan96/Documents/src/speaker

MAX_ITERATIONS=50
iteration=0

while [ $iteration -lt $MAX_ITERATIONS ]; do
    echo "=== Iteration $((iteration+1)) ==="
    
    # Build package
    R CMD build . --no-build-vignettes >/dev/null 2>&1
    
    # Clean lock
    rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-speaker
    
    # Try to install and capture missing symbol
    install_output=$(R CMD INSTALL speaker_0.4.1.tar.gz 2>&1)
    
    # Check if installed successfully
    if echo "$install_output" | grep -q "DONE\|successfully"; then
        echo "✅ Package installed successfully!"
        exit 0
    fi
    
    # Extract missing symbol
    missing_symbol=$(echo "$install_output" | grep "symbol not found" | tail -1 | sed 's/.*in flat namespace .//; s/.//')
    
    if [ -z "$missing_symbol" ]; then
        echo "No missing symbol found, but installation failed"
        echo "$install_output" | tail -20
        exit 1
    fi
    
    echo "Missing symbol: $missing_symbol"
    
    # Demangle the symbol to understand it better
    if command -v c++filt &> /dev/null; then
        demangled=$(echo "$missing_symbol" | c++filt)
        echo "Demangled: $demangled"
    fi
    
    ((iteration++))
done

echo "❌ Reached maximum iterations without success"
exit 1
