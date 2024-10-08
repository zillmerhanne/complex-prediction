#!/bin/bash -l
# Standard output and error:
#SBATCH -o ./logs/slurm/job.out.%j
#SBATCH -e ./logs/slurm/job.err.%j
# Initial working directory:
#SBATCH -D ./
# Job name
#SBATCH -J CombfoldWorkflow
#
#SBATCH --ntasks=1
#SBATCH --gres=gpu:a100:1
#SBATCH --cpus-per-task=18
#SBATCH --mem=32000
#SBATCH --time=24:00:00  # Specify the runtime (24 hours in this case)
#
mkdir logs/slurm -p
srun workflow/scripts/slurmer.sh
