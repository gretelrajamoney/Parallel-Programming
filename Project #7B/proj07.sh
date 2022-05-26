# NAME: Gretel Rajamoney
# ASSIGNMENT: Project #7B 
# Autocorrelation Using MPI

# REFERENCE: Slide 8 of Message Passing Interface (MPI)
#!/bin/bash
#SBATCH -J proj07
#SBATCH -A cs475-575
#SBATCH -p class
#SBATCH -N 4 # number of nodes
#SBATCH -n 4 # number of tasks 
#SBATCH -o proj07.out
#SBATCH -e proj07.err
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=rajamong@oregonstate.edu

module load openmpi/3.1
mpic++ proj07.cpp -o proj07 -lm

for n in 1 2 4 8 12 16
do
    mpiexec -mca btl self,tcp -np $n proj07    
    ./proj07
done