#!/bin/bash
#SBATCH --job-name=default
#SBATCH --time=01:00:00
#SBATCH --gres=gpu:a100:1

for f in "$@"; do
    echo "Running $f..."
    bash "$f"
done