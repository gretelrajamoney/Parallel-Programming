#!/bin/bash
#SBATCH -J proj05
#SBATCH -A cs475-575
#SBATCH -p class
#SBATCH --gres=gpu:1
#SBATCH -o proj05.out
#SBATCH -e proj05.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=rajamong@oregonstate.edu


printf "PART 1: Multiply Two Arrays Using OpenCL"
printf "\n"
printf "\n"
printf "   GLOBAL    LOCAL    WORK GROUPS   PERFORMANCE"
printf "\n"
for t in 1024 4096 16384 65536 262144 1048576 2097152 4194304 8388608
do
  for n in 8 16 32 64 128 256 512
  do
    g++ -o first -DNMB=$t -DLOCAL_SIZE=$n first.cpp /usr/local/apps/cuda/10.1/lib64/libOpenCL.so.1.1 -lm -fopenmp
    ./first
  done
done

printf "\n"
printf "\n"
printf "PART 2: Multiply Two Arrays Together and Add a Third Using OpenCL"
printf "\n"
printf "\n"
printf "   GLOBAL    LOCAL    WORK GROUPS   PERFORMANCE"
printf "\n"
for t in 1024 4096 16384 65536 262144 1048576 2097152 4194304 8388608
do
  for n in 8 16 32 64 128 256 512
  do
    g++ -o second -DNMB=$t -DLOCAL_SIZE=$n second.cpp /usr/local/apps/cuda/10.1/lib64/libOpenCL.so.1.1 -lm -fopenmp
    ./second
  done
done

printf "\n"
printf "\n"
printf "PART 3: Multiply Two Arrays but with a Reduction"
printf "\n"
printf "\n"
printf "   GLOBAL    LOCAL    WORK GROUPS   PERFORMANCE"
printf "\n"
for t in 1024 4096 16384 65536 262144 1048576 2097152 4194304 8388608
do
  for n in 32 64 128 256
  do
    g++ -o third -DNMB=$t -DLOCAL_SIZE=$n third.cpp /usr/local/apps/cuda/10.1/lib64/libOpenCL.so.1.1 -lm -fopenmp
    ./third
  done
done