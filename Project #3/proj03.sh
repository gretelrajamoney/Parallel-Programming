#!/bin/bash

echo "date, deer, cheetah, height, precip, temperature"
g++ -O3   proj03.cpp  -o  proj03  -lm  -fopenmp
./proj03
