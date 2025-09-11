#!/bin/bash
#SBATCH --job-name=pycharm_sshd
#SBATCH --output=logs/pycharm_sshd-%j.out
#SBATCH --error=logs/pycharm_sshd-%j.err
#SBATCH --time=23:59:00
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --gres=gpu:h100:1
#SBATCH --partition=h100

DATA_ROOT=${UCO3D_PATH}/uco3d
SUPER="household_appliances"
set -euo pipefail

# Pick a free high port
PORT=$(python - <<'PY'
import socket
s=socket.socket(); s.bind(("",0)); print(s.getsockname()[1]); s.close()
PY
)

# Generate a host key just for this job (don’t reuse your personal key as a host key)
JOBDIR="${HOME}/.pycharm-slurm"
mkdir -p "${JOBDIR}"
HOSTKEY="${JOBDIR}/sshd_host_ed25519_key"
[ -f "${HOSTKEY}" ] || ssh-keygen -t ed25519 -N "" -f "${HOSTKEY}" >/dev/null
NODE="$(hostname)"
echo "${NODE}:${PORT}" | tee "${JOBDIR}/endpoint"

echo "Compute node: ${NODE}"
echo "Listening on port: ${PORT}"
echo "TMPDIR: ${TMPDIR}"

# Start sshd in the foreground to keep the allocation alive
# -F /dev/null uses defaults; authorized_keys stays at ~/.ssh/authorized_keys
umask 077
ENVFILE="$HOME/.ssh/environment"
printf 'TMPDIR=%s\n' "$TMPDIR" > "$ENVFILE"
bash $HOME/bin/stage_uco3d_category.sh "$SUPER" "$DATA_ROOT" 16
exec /usr/sbin/sshd -D -p "${PORT}" -f /dev/null -h "${HOSTKEY}" \
  -o PermitUserRC=yes \
  -o X11Forwarding=yes