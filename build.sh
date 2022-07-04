#!/usr/bin/env bash

set -e
set -u

bison polish.y
cc polish.tab.c -lm -o polish
