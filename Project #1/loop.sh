#!/bin/bash

echo "num threads, num trials, probability, megatrials"
for t in 1 2 4 8 12 16 20 24 32
do
  # echo NUMT = $t
  for n in 1 10 100 1000 10000 100000 500000 1000000
  do
    # echo NUMS = $n
    g++ -O3   MonteCarloSimulation.cpp  -DNUMT=$t -DNUMTRIALS=$n  -o MonteCarloSimulation  -lm  -fopenmp
    ./MonteCarloSimulation
  done
done