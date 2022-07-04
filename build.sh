#!/usr/bin/env bash

set -e
set -u

bison polish.y
echo "=================================="
cc polish.tab.c -lm -o polish
