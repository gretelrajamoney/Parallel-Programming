#!/bin/bash

echo "num threads, num nodes, volume, max performance"
for t in 1 2 4 8 12 16 20 24 32
do
  # echo NUMT = $t
  for n in 100 250 500 750 1000 2500 5000 7500 10000
  do
    # echo NUMN = $n
    g++ -O3   proj02.cpp  -DNUMT=$t -DNUMN=$n  -o proj02  -lm  -fopenmp
    ./proj02
  done
done