#!/bin/bash
# Automated stub addition loop
cd /Users/frkkan96/Documents/src/speaker

for iteration in {1..50}; do
    echo "=== Iteration $iteration ==="
    
    # Build
    R CMD build --no-build-vignettes . >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo "Build failed"
        exit 1
    fi
    
    # Clean lock
    rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-speaker
    
    # Install
    R CMD INSTALL speaker_0.4.1.tar.gz >install_output.txt 2>&1
    
    # Check if installed
    if echo "$output" | grep -q "DONE.*successfully"; then
        echo "✅ SUCCESS!"
        exit 0
    fi
    
    # Get missing symbol
    symbol=$(grep "symbol not found" install_output.txt | tail -1 | sed 's/.*flat namespace .//; s/.$//')
    
    if [ -z "$symbol" ]; then
        # Check if it loaded anyway
        R -q -e "library(speaker)" >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            echo "✅ Package loads successfully!"
            exit 0
        else
            echo "Failed but no symbol found"
            tail -20 install_output.txt
            exit 1
        fi
    fi
    
    echo "Missing: $symbol"
    
    # Demangle
    demangled=$(echo "$symbol" | c++filt 2>/dev/null)
    echo "Demangled: $demangled"
    
    # Log it
    echo "$symbol" >> missing_symbols_found.txt
    
    sleep 1
done

echo "Completed $iteration iterations"
