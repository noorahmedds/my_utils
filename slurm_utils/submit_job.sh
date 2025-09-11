#!/bin/bash
#SBATCH --job-name=default
#SBATCH --time=06:00:00
#SBATCH --cpus-per-task=4
#SBATCH --gres=gpu:a100:1
#SBATCH --error="slurm_logs/%x_%j.err"
#SBATCH --out="slurm_logs/%x_%j.out"

# ^^^ All of these are just defaults; override at submit time, e.g.:
# sbatch --time=2:00:00 --cpus-per-task=8 --gres=gpu:a100:1 submit_job.sh /working_directory conda_env_name -- python train.py --epochs 10
# sbatch --time=7:00:00 --cpus-per-task=8 --gres=gpu:h100:1 submit_job.sh ~/projects/superdec superdec_p3_11 -- ./scripts/train_vanilla.sh
# sbatch --job-name=eval_something --time=5:00:00 --gres=gpu:a100:1 submit_job.sh "$(pwd)" pytorch-latest -- scripts/eval.sh

set -euo pipefail

# source ~/.bash_profile

WORKDIR="$1"
CONDA_ENV="$2"

echo "Working directory: $WORKDIR"
echo "Conda environment: $CONDA_ENV"

# Require a literal -- separator before the command (so sbatch options can't be confused with your command)
if [[ "${3:-}" != "--" ]]; then
  echo "ERROR: expected '--' after <WORK_DIR> <CONDA_ENV> and before your command."
  echo "Example: sbatch submit_job.sh /path/to/working_dir conda_env_name -- python train.py --epochs 10"
  exit 2
fi


# Ensure working dir exists and create a logs folder inside it
if [[ ! -d "$WORKDIR" ]]; then
  echo "ERROR: Work directory '$WORKDIR' does not exist."
  exit 1
fi

shift 2

# Require a literal -- separator before the command (so sbatch options can't be confused with your command)
if [[ "${1:-}" != "--" ]]; then
    echo "ERROR: expected '--' after <WORKDIR> <CONDA_ENV> and before your command."
    echo "Example: sbatch submit_job.sh /path/to/dir myenv -- python train.py --epochs 10"
    exit 2
fi
shift

# The remainder is your command
CMD=("$@")

# Optional: put your environment setup here (edit as needed)
conda activate "$CONDA_ENV"

# Change to the requested working directory
cd "$WORKDIR"

echo "-------------------------------------"
echo "Final command to run (with srun):"
echo "  srun ${CMD[*]}"
echo "From the working directory:"
echo "  $WORKDIR"
echo "-------------------------------------"

START_SEC=$(date +%s)
${CMD[@]}
RC=$?
END_SEC=$(date +%s)

DUR=$((END_SEC - START_SEC))
echo "========== SLURM JOB END ============"
echo " End time       : $(date -Is)"
echo " Duration (sec) : $DUR"
echo " Exit code      : $RC"

exit "$RC"