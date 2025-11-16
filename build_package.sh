#!/bin/bash
cd /Users/frkkan96/Documents/src/speaker
/Library/Frameworks/R.framework/Resources/bin/R CMD build . > build.log 2>&1
tail -100 build.log
