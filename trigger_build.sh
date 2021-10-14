#!/bin/bash

git submodule foreach git pull origin main
date > trigger.txt
git add trigger.txt
git commit trigger.txt -m "Auto-generated commit"
git pull
git push
