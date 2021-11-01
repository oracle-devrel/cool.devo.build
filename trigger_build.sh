#!/bin/bash

# this script trigger jekyll to rebuild the whole site
#
# Note: it only works if you have devo.tutorials cloned into tutorials
# - if you want to clone submodules into the existing directory, run
#   git submodule update --init --recursive
#   
# - if you need a full clone chckout, run:
#   git clone --recursive git@github.com:oracle-devrel/cool.devo.build.git

git submodule foreach git pull origin main
date > trigger.txt
git add trigger.txt tutorials
git commit -m "Auto-generated commit"
git pull
git push
