#!/bin/bash
#SBATCH -J proj05
#SBATCH -A cs475-575
#SBATCH -p class
#SBATCH --constraint=v100
#SBATCH --gres=gpu:1
#SBATCH -o proj05.out
#SBATCH -e proj05.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=rajamong@oregonstate.edu
for t in 1024 4096 16384 65536 262144 1048576 2097152 4194304
do
  for b in 8 32 128
  do
    /usr/local/apps/cuda/cuda-10.1/bin/nvcc -DNUMTRIALS=$t -DBLOCKSIZE=$b -o proj05  proj05.cu
    ./proj05
  done
done