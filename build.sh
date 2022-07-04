#!/usr/bin/env bash

set -e
set -u

echo "=================================="
bison polish.y
echo "=================================="
cc polish.tab.c -lm -o polish

echo "=================================="
bison aaa.yy
echo "=================================="
c++ --std=c++14  aaa.tab.cc -lm -o aaa
