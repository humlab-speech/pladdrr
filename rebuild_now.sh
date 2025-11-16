#!/bin/zsh
cd /Users/frkkan96/Documents/src/speaker
R CMD build . 2>&1 | tee build.log
echo "Build completed. Check build.log for details."
