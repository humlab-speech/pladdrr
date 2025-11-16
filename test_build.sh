#!/bin/zsh
cd /Users/frkkan96/Documents/src/speaker
/Library/Frameworks/R.framework/Resources/bin/R CMD INSTALL --preclean --no-multiarch --with-keep.source . 2>&1 | tee install.log
