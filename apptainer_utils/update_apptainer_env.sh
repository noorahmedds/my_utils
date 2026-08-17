#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: update_apptainer_env.sh --sif PATH --mode {overwrite|append} [options]

Automate sandbox build -> venv pip install -> SIF repack for Apptainer images.

Required:
  --sif PATH              Source .sif file
  --mode MODE             overwrite | append

Pip input (required unless --interactive or --skip-pip):
  -r, --requirements FILE Requirements file passed to pip
  -p, --package PKG       Pip target (repeatable)

Conditional:
  --suffix NAME           Required for append mode (e.g. trnsf450)
  --confirm-overwrite     Required for overwrite mode

Optional:
  --sandbox-name NAME     Sandbox dir name under $TMPDIR (default: {stem}_sandbox)
  --pip-args "..."        Extra flags forwarded to pip
  --interactive           Open writable shell instead of automated pip install
  --skip-sandbox-build    Reuse existing sandbox (for interactive round-trips)
  --skip-pip              Skip pip install step
  --keep-sandbox          Do not remove sandbox after success
  --force                 Overwrite existing output SIF in append mode
  --no-proxy              Skip auto NHR proxy export
  --dry-run               Print resolved commands without executing
  -h, --help              Show this help

Examples:
  update_apptainer_env.sh --sif $ENV_DIR/pytorch3d_torch260_cu124_flashattn.sif \
    -p "transformers==4.50.0" --mode append --suffix trnsf450

  update_apptainer_env.sh --sif $ENV_DIR/pytorch3d_torch260_cu124_flashattn.sif \
    -p geomloss --mode overwrite --confirm-overwrite

  update_apptainer_env.sh --sif $ENV_DIR/pytorch3d_torch260_cu124_flashattn.sif \
    --interactive --mode append --suffix minkowski
EOF
}

die() {
    echo "error: $*" >&2
    exit 1
}

run_cmd() {
    if [[ "$DRY_RUN" == "1" ]]; then
        printf '[dry-run]'
        printf ' %q' "$@"
        echo
    else
        "$@"
    fi
}

SOURCE_SIF=""
MODE=""
SUFFIX=""
SANDBOX_NAME=""
PIP_ARGS=""
REQUIREMENTS=""
declare -a PACKAGES=()
CONFIRM_OVERWRITE=0
INTERACTIVE=0
SKIP_SANDBOX_BUILD=0
SKIP_PIP=0
KEEP_SANDBOX=0
FORCE=0
NO_PROXY=0
DRY_RUN=0

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sif)
            SOURCE_SIF="$2"
            shift 2
            ;;
        --sif=*)
            SOURCE_SIF="${1#*=}"
            shift
            ;;
        --mode)
            MODE="$2"
            shift 2
            ;;
        --mode=*)
            MODE="${1#*=}"
            shift
            ;;
        --suffix)
            SUFFIX="$2"
            shift 2
            ;;
        --suffix=*)
            SUFFIX="${1#*=}"
            shift
            ;;
        --sandbox-name)
            SANDBOX_NAME="$2"
            shift 2
            ;;
        --sandbox-name=*)
            SANDBOX_NAME="${1#*=}"
            shift
            ;;
        --pip-args)
            PIP_ARGS="$2"
            shift 2
            ;;
        --pip-args=*)
            PIP_ARGS="${1#*=}"
            shift
            ;;
        -r|--requirements)
            REQUIREMENTS="$2"
            shift 2
            ;;
        --requirements=*)
            REQUIREMENTS="${1#*=}"
            shift
            ;;
        -p|--package)
            PACKAGES+=("$2")
            shift 2
            ;;
        --package=*)
            PACKAGES+=("${1#*=}")
            shift
            ;;
        --confirm-overwrite)
            CONFIRM_OVERWRITE=1
            shift
            ;;
        --interactive)
            INTERACTIVE=1
            shift
            ;;
        --skip-sandbox-build)
            SKIP_SANDBOX_BUILD=1
            shift
            ;;
        --skip-pip)
            SKIP_PIP=1
            shift
            ;;
        --keep-sandbox)
            KEEP_SANDBOX=1
            shift
            ;;
        --force)
            FORCE=1
            shift
            ;;
        --no-proxy)
            NO_PROXY=1
            shift
            ;;
        --dry-run)
            DRY_RUN=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "unknown argument: $1 (use --help)"
            ;;
    esac
done

[[ -n "$SOURCE_SIF" ]] || die "--sif is required"
[[ -n "$MODE" ]] || die "--mode is required"
[[ "$MODE" == "overwrite" || "$MODE" == "append" ]] || die "--mode must be overwrite or append"

if [[ "$MODE" == "append" ]]; then
    [[ -n "$SUFFIX" ]] || die "--suffix is required for append mode"
fi

if [[ "$MODE" == "overwrite" ]]; then
    [[ "$CONFIRM_OVERWRITE" == "1" ]] || die "--confirm-overwrite is required for overwrite mode"
fi

if [[ "$INTERACTIVE" == "0" && "$SKIP_PIP" == "0" ]]; then
    [[ -n "$REQUIREMENTS" || ${#PACKAGES[@]} -gt 0 ]] || die "provide -r/--requirements or -p/--package (or use --interactive / --skip-pip)"
fi

command -v apptainer >/dev/null 2>&1 || die "apptainer not found on PATH"

if [[ -z "${TMPDIR:-}" ]]; then
    die "TMPDIR is not set"
fi
if [[ ! -d "$TMPDIR" || ! -w "$TMPDIR" ]]; then
    die "TMPDIR is not writable: $TMPDIR"
fi

SOURCE_SIF="$(readlink -f "$SOURCE_SIF" 2>/dev/null || realpath "$SOURCE_SIF")"
[[ -f "$SOURCE_SIF" && -r "$SOURCE_SIF" ]] || die "source SIF not found or not readable: $SOURCE_SIF"

SOURCE_DIR="$(dirname "$SOURCE_SIF")"
SOURCE_BASENAME="$(basename "$SOURCE_SIF")"
SOURCE_STEM="${SOURCE_BASENAME%.sif}"

if [[ -z "$SANDBOX_NAME" ]]; then
    SANDBOX_NAME="${SOURCE_STEM}_sandbox"
fi
SANDBOX="${TMPDIR%/}/${SANDBOX_NAME}"

if [[ "$MODE" == "append" ]]; then
    OUTPUT_SIF="${SOURCE_DIR}/${SOURCE_STEM}_${SUFFIX}.sif"
else
    OUTPUT_SIF="$SOURCE_SIF"
fi

if [[ "$MODE" == "append" && -f "$OUTPUT_SIF" && "$FORCE" != "1" ]]; then
    die "output SIF already exists: $OUTPUT_SIF (use --force to overwrite)"
fi

if [[ -n "$REQUIREMENTS" ]]; then
    REQUIREMENTS="$(readlink -f "$REQUIREMENTS" 2>/dev/null || realpath "$REQUIREMENTS")"
    [[ -f "$REQUIREMENTS" ]] || die "requirements file not found: $REQUIREMENTS"
fi

if [[ "$NO_PROXY" == "0" ]]; then
    export http_proxy="${http_proxy:-http://proxy.nhr.fau.de:80}"
    export https_proxy="${https_proxy:-http://proxy.nhr.fau.de:80}"
fi

SOURCE_SIZE_HR="$(du -h "$SOURCE_SIF" | awk '{print $1}')"
echo "source SIF:  $SOURCE_SIF ($SOURCE_SIZE_HR)"
echo "sandbox:     $SANDBOX"
echo "output SIF:  $OUTPUT_SIF"
echo "mode:        $MODE"
echo "warning: sandbox + rebuilt SIF may need ~2x source image disk space"

cleanup_sandbox() {
    if [[ "$KEEP_SANDBOX" == "1" || "$DRY_RUN" == "1" ]]; then
        return 0
    fi
    if [[ -d "$SANDBOX" ]]; then
        rm -rf "$SANDBOX"
    fi
}

if [[ "$KEEP_SANDBOX" == "0" ]]; then
    trap cleanup_sandbox EXIT
fi

if [[ "$SKIP_SANDBOX_BUILD" == "0" ]]; then
    if [[ -e "$SANDBOX" ]]; then
        die "sandbox already exists: $SANDBOX (remove it or use --skip-sandbox-build)"
    fi
    run_cmd apptainer build --sandbox "$SANDBOX" "$SOURCE_SIF"
else
    [[ -d "$SANDBOX" ]] || die "sandbox not found for --skip-sandbox-build: $SANDBOX"
    echo "reusing sandbox: $SANDBOX"
fi

APPTAINER_RUN=(apptainer exec --nv --fakeroot --writable --no-home)

if [[ "$INTERACTIVE" == "1" ]]; then
    REBUILD_CMD=(
        "$0" --sif "$SOURCE_SIF" --mode "$MODE"
    )
    if [[ "$MODE" == "append" ]]; then
        REBUILD_CMD+=(--suffix "$SUFFIX")
    fi
    if [[ "$MODE" == "overwrite" ]]; then
        REBUILD_CMD+=(--confirm-overwrite)
    fi
    REBUILD_CMD+=(--skip-sandbox-build --skip-pip)
    if [[ "$KEEP_SANDBOX" == "1" ]]; then
        REBUILD_CMD+=(--keep-sandbox)
    fi
    if [[ "$FORCE" == "1" ]]; then
        REBUILD_CMD+=(--force)
    fi

    echo
    echo "Opening interactive shell. Inside the container run:"
    echo "  source /opt/venv/bin/activate"
    echo "After manual installs, exit and rebuild the SIF with:"
    printf '  %q' "${REBUILD_CMD[@]}"
    echo
    echo
    if [[ "$DRY_RUN" == "1" ]]; then
        run_cmd apptainer shell --nv --fakeroot --writable --no-home "$SANDBOX"
        trap - EXIT
        echo "interactive dry-run complete; skipping SIF rebuild"
        exit 0
    fi
    trap - EXIT
    apptainer shell --nv --fakeroot --writable --no-home "$SANDBOX"
    if [[ "$KEEP_SANDBOX" == "1" ]]; then
        echo "sandbox kept at: $SANDBOX"
    else
        cleanup_sandbox
    fi
    echo "interactive session complete; rebuild the SIF with the command printed above"
    exit 0
elif [[ "$SKIP_PIP" == "0" ]]; then
    declare -a PIP_INSTALL_ARGS=()
    declare -a BIND_ARGS=()

    if [[ -n "$REQUIREMENTS" ]]; then
        REQ_DIR="$(dirname "$REQUIREMENTS")"
        REQ_BASE="$(basename "$REQUIREMENTS")"
        BIND_ARGS=(-B "${REQ_DIR}:/req")
        PIP_INSTALL_ARGS+=(-r "/req/${REQ_BASE}")
    fi

    if [[ ${#PACKAGES[@]} -gt 0 ]]; then
        PIP_INSTALL_ARGS+=("${PACKAGES[@]}")
    fi

    if [[ -n "$PIP_ARGS" ]]; then
        # shellcheck disable=SC2206
        EXTRA_PIP_ARGS=($PIP_ARGS)
        PIP_INSTALL_ARGS+=("${EXTRA_PIP_ARGS[@]}")
    fi

    PIP_CMD=(python -m pip install "${PIP_INSTALL_ARGS[@]}")
    INNER_CMD="source /opt/venv/bin/activate && $(printf '%q ' "${PIP_CMD[@]}")"

    if [[ ${#BIND_ARGS[@]} -gt 0 ]]; then
        run_cmd "${APPTAINER_RUN[@]}" "${BIND_ARGS[@]}" "$SANDBOX" bash -lc "$INNER_CMD"
    else
        run_cmd "${APPTAINER_RUN[@]}" "$SANDBOX" bash -lc "$INNER_CMD"
    fi
else
    echo "skipping pip install"
fi

if [[ "$MODE" == "overwrite" ]]; then
    BACKUP_SIF="${SOURCE_SIF}.bak.$(date +%Y%m%d_%H%M%S)"
    echo "backing up source SIF to: $BACKUP_SIF"
    run_cmd cp -a "$SOURCE_SIF" "$BACKUP_SIF"
fi

TMP_OUT="${OUTPUT_SIF}.building.$$"
run_cmd apptainer build "$TMP_OUT" "$SANDBOX"
run_cmd mv -f "$TMP_OUT" "$OUTPUT_SIF"

trap - EXIT
cleanup_sandbox

echo
echo "done: $OUTPUT_SIF"
OUTPUT_SIZE_HR="$(du -h "$OUTPUT_SIF" 2>/dev/null | awk '{print $1}' || echo "unknown")"
echo "output size: $OUTPUT_SIZE_HR"
