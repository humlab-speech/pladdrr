#!/bin/zsh
cd /Users/frkkan96/Documents/src/speaker
/Library/Frameworks/R.framework/Resources/bin/R CMD build . > build.log 2>&1
echo "Build completed - check build.log for results"
