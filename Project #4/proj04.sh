#!/bin/bash

echo "Array Size, Non-SIMD Multiplication Performance, SIMD Multiplication Performance, Multiplication Speed-Up, Non-SIMD Multiplication Sum Performance, SIMD Multiplication Sum Performance, Multiplication Sum Speed-Up"
for s in 1000 8000 10000 80000 100000 800000 1000000 4000000 8000000
do
    g++ -DARRAYSIZE=$s proj04.cpp -o proj04 -lm -fopenmp
    ./proj04
done