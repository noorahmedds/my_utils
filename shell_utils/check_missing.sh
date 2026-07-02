#!/usr/bin/env bash
# usage: check_missing.sh <root_dir> <filename_or_relative_path>
# Example: check_missing.sh /data/experiments metrics.json

# Finds missing files in model directories under root:
# - parent of each special folder (see SPECIAL_FOLDERS)
# - deepest directories when no special folder exists on that branch

set -euo pipefail

ROOT="${1:?root directory required}"
TARGET="${2:?file path required (relative to each check dir)}"

if [[ ! -d "$ROOT" ]]; then
  echo "error: not a directory: $ROOT" >&2
  exit 2
fi

missing=0
found=0
check_dir_count=0

SPECIAL_FOLDERS=(renders objs zbuf)
SPECIAL_FOLDERS_REGEX='(renders|objs|zbuf)'

# True if dir or any ancestor up to subtree root has a special-folder child.
has_special_ancestor() {
  local dir="$1"
  local stop="${2%/}"
  local p="$dir"

  while [[ "$p" != "/" ]]; do
    for folder in "${SPECIAL_FOLDERS[@]}"; do
      [[ -d "$p/$folder" ]] && return 0
    done
    [[ "$p" == "$stop" ]] && break
    p=$(dirname "$p")
  done
  return 1
}

# Deepest dirs in a subtree, skipping special folders and their contents.
# Excludes dirs under a branch that already has any special folder (those use the parent-of-folder rule).
find_deepest_dirs_without_special_folders() {
  local subtree="$1"
  local max_depth

  max_depth=$(
    find "$subtree" \
      -regextype posix-extended -regex ".*/${SPECIAL_FOLDERS_REGEX}(/.*)?" -prune -o \
      -type d -printf '%d\n' \
    | sort -n | tail -1
  )
  [[ -n "${max_depth:-}" ]] || return 0

  find "$subtree" \
    -regextype posix-extended -regex ".*/${SPECIAL_FOLDERS_REGEX}(/.*)?" -prune -o \
    -type d -printf '%d\0%p\0' |
  while IFS= read -r -d '' depth && IFS= read -r -d '' dir; do
    if (( depth == max_depth )) && ! has_special_ancestor "$dir" "$subtree"; then
      printf '%s\0' "$dir"
    fi
  done
}

# Union of parents-of-special-folders and deepest dirs without any special folder on that branch.
find_check_dirs() {
  local subtree="$1"
  {
    find "$subtree" -type d -regextype posix-extended -regex ".*/${SPECIAL_FOLDERS_REGEX}$" -printf '%h\0'
    find_deepest_dirs_without_special_folders "$subtree"
  } | sort -uz
}

# Collect subtrees: each immediate child of ROOT, or ROOT itself if it has none.
subtrees=()
if compgen -G "$ROOT"/*/ > /dev/null; then
  for d in "$ROOT"/*/; do
    subtrees+=("$d")
  done
else
  subtrees+=("$ROOT")
fi

# Check each candidate dir for the target file
while IFS= read -r -d '' dir; do
  check_dir_count=$((check_dir_count + 1))
  if [[ -e "$dir/$TARGET" ]]; then
    found=$((found + 1))
  else
    missing=$((missing + 1))
    echo "MISSING: $dir/$TARGET"
    echo "  check dir: $dir"
  fi
done < <(
  for subtree in "${subtrees[@]}"; do
    find_check_dirs "$subtree"
  done
)

echo
echo "Summary: $check_dir_count check dirs, $found have '$TARGET', $missing missing"

# exit 1 if any check dir is missing the file
[[ "$missing" -eq 0 ]]
