#!/bin/bash
# Automated stub addition script

cd /Users/frkkan96/Documents/src/speaker

for i in {1..100}; do
    echo "=== Iteration $i ==="
    
    # Build
    R CMD build . --no-build-vignettes >/dev/null 2>&1
    
    # Clean lock
    rm -rf /Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/00LOCK-speaker
    
    # Try install
    output=$(R CMD INSTALL speaker_0.4.1.tar.gz 2>&1)
    
    # Check success
    if echo "$output" | grep -q "DONE.*successfully"; then
        echo "✅ SUCCESS! Package installed!"
        exit 0
    fi
    
    # Check if compilation failed
    if echo "$output" | grep -q "compilation failed"; then
        echo "❌ Compilation error"
        echo "$output" | tail -20
        exit 1
    fi
    
    # Extract missing symbol
    symbol=$(echo "$output" | grep "symbol not found" | tail -1 | sed 's/.*_in flat namespace .//; s/.//')
    
    if [ -z "$symbol" ]; then
        # Check for other errors
        if echo "$output" | grep -q "loading failed"; then
            echo "❌ Loading failed but no symbol found"
            echo "$output" | tail -10
            exit 1
        else
            echo "✅ Might be successful - checking..."
            if [ -d "/Library/Frameworks/R.framework/Versions/4.4-arm64/Resources/library/speaker" ]; then
                echo "✅ Package is installed!"
                exit 0
            fi
        fi
        break
    fi
    
    # Demangle
    demangled=$(echo "$symbol" | c++filt 2>/dev/null)
    echo "Missing: $symbol"
    echo "Demangled: $demangled"
    
    # Brief pause
    sleep 1
done

echo "Reached iteration limit"
