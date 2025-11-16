#!/bin/zsh
cd /Users/frkkan96/Documents/src/speaker
/Library/Frameworks/R.framework/Resources/bin/R CMD build . 2>&1 | tee build.log
