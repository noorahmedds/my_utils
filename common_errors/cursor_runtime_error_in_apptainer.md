# Runtime error in apptainer
_Exported on 7/31/2026 at 18:19:50 GMT+2 from Cursor (3.7.12)_

---

**User**

For my apptainer environment present at /hnvme/workspace/v114be10-noor_envs/pytorch3d_torch260_cu124_flashattn.sif when i am building into a tmpdirectory and using sandbox to install a lib and again running my scripts (like I normally do with apptainer_wrapper). I am running into the following run_time error 
RuntimeError: Error building extension '_pvcnn_backend': ninja: error: stat(/home/hpc/b266be/b266be11/projects/superdec/superdec/functional/src/voxelization/vox.cpp): Permission denied

For some context I was previously on a different HPC user (b266be10) and now im running all these commands from v114be10. I think there is some carry over caches which are used when im in sandbox mode or something. Can you explain the issue and suggest some fixes

---

**Cursor**

The error path points at another user’s home (`b266be11`), so this is likely a stale absolute path in a JIT/extension build cache. I’ll trace how PVCNN and your Apptainer wrapper resolve build dirs and caches.

Confirming this is JIT extension cache with absolute paths. Checking where that cache lives in your env and whether the SIF was inherited from the old user.

Your diagnosis is right: this is **stale JIT build-cache carryover**, not a broken Apptainer install of the new library.

## What’s going wrong

PVCNN’s CUDA ops are **not** a normal pip package. They’re JIT-compiled on import here:

```8:17:/home/hpc/v114be/v114be10/projects/superdec/superdec/functional/backend.py
_backend = load(name='_pvcnn_backend',
                extra_cflags=['-O3', '-std=c++17'],
                sources=[os.path.join(_src_path,'src', f) for f in [
                    'voxelization/vox.cpp',
                    'voxelization/vox.cu',
                    'interpolate/trilinear_devox.cpp',
                    'interpolate/trilinear_devox.cu',
                    'bindings.cpp',
                ]]
                )
```

`torch.utils.cpp_extension.load` writes a ninja build under something like:

`~/.cache/torch_extensions/py310_cu124/_pvcnn_backend/`

That cache stores **absolute host paths** in `build.ninja` / `.ninja_deps`. Your error:

```text
stat(/home/hpc/b266be/b266be11/projects/superdec/.../vox.cpp): Permission denied
```

means ninja is still trying to touch sources from the **old account**. As `v114be10` you cannot read that tree (confirmed), so rebuild dies.

Your command history also shows long use of `/hnvme/workspace/b266be11-noor_envs/...` and sandbox rebuilds from those SIFs, so this is exactly the migration footprint you’d expect.

You already have a host cache at:

`/home/hpc/v114be/v114be10/.cache/torch_extensions/py310_cu124/_pvcnn_backend/`

That one currently points at `v114be10` paths. The failing run is almost certainly using a **different** cache that still has `b266be11` paths — most often:

1. **Sandbox / `--no-home`**: cache lands in `/root/.cache/torch_extensions` inside the writable sandbox, then gets **baked into the SIF** on `apptainer build`.
2. An old leftover sandbox under `$TMPDIR`.
3. Rarely: a copied/migrated `~/.cache` from the old user.

Sandbox pip installs do not clear this; the next import of PVCNN just reuses the poisoned ninja tree.

## Fixes (in order)

### 1. Blow away the JIT cache (usually enough)

On the host:

```bash
rm -rf ~/.cache/torch_extensions/*/_pvcnn_backend
# or nuclear:
rm -rf ~/.cache/torch_extensions
```

If you use sandbox with `--no-home`:

```bash
# inside writable sandbox
rm -rf /root/.cache/torch_extensions
```

Then rebuild the SIF if that `/root` cache was already packed in.

Force a clean rebuild location for the next run:

```bash
export TORCH_EXTENSIONS_DIR="${TMPDIR:-/tmp}/torch_extensions_${USER}"
mkdir -p "$TORCH_EXTENSIONS_DIR"
```

### 2. Confirm which cache is actually used

Inside the same `apptainer` invocation that fails:

```bash
python - <<'PY'
from torch.utils.cpp_extension import _get_build_directory
print(_get_build_directory('_pvcnn_backend', verbose=True))
PY
```

Inspect that directory’s `build.ninja` for `b266be11`. If present, delete that whole `_pvcnn_backend` dir.

### 3. Don’t bake JIT artifacts into the image

When doing sandbox → install → repack:

- Prefer `--no-home` (you already do).
- Before `apptainer build ... sif sandbox/`, clear `/root/.cache/torch_extensions` (and maybe `/root/.cache` generally).
- Avoid importing `superdec` / PVCNN inside the sandbox unless you intend a clean rebuild with current source paths.

### 4. Longer-term (more robust)

Compile `_pvcnn_backend` once as a real extension into the venv during image build (setup.py / `CUDAExtension`), instead of JIT `load()` at import. That removes dependence on host absolute paths and ninja caches.

---

**Bottom line:** the new pip install is fine; a leftover `_pvcnn_backend` ninja cache still references `/home/hpc/b266be/b266be11/...`, and ninja can’t `stat` it under `v114be10`. Delete that cache (host and/or `/root` inside sandbox/SIF), optionally set `TORCH_EXTENSIONS_DIR`, and let it rebuild against `/home/hpc/v114be/v114be10/projects/superdec/...`.

---

**User**

how can i an environment variable permanetly inside my sif file

---

**Cursor**

I'll check how your SIF build/update flow works so the advice matches your setup.

For an existing SIF (your sandbox → rebuild flow), put the export in Apptainer’s env scripts inside the writable sandbox, then rebuild.

## Recommended: sandbox edit + rebuild

```bash
apptainer build --sandbox $TMPDIR/pytorch_env $ENV_DIR/pytorch3d_torch260_cu124_flashattn.sif
apptainer shell --fakeroot --writable --no-home $TMPDIR/pytorch_env
```

Inside the sandbox:

```bash
mkdir -p /.singularity.d/env
cat > /.singularity.d/env/99-custom.sh <<'EOF'
#!/bin/sh
export TORCH_EXTENSIONS_DIR=/opt/torch_extensions
# export ANY_OTHER_VAR=value
EOF
chmod +x /.singularity.d/env/99-custom.sh
mkdir -p /opt/torch_extensions
exit
```

Then repack:

```bash
apptainer build $ENV_DIR/pytorch3d_torch260_cu124_flashattn.sif $TMPDIR/pytorch_env
```

Anything in `/.singularity.d/env/*.sh` is sourced on every `apptainer exec/run/shell`.

## Alternative: definition file `%environment`

If you build from a `.def`:

```singularity
Bootstrap: localimage
From: /path/to/base.sif

%environment
    export TORCH_EXTENSIONS_DIR=/opt/torch_extensions

%post
    mkdir -p /opt/torch_extensions
```

Then `apptainer build new.sif recipe.def`.

## What is *not* permanent in the SIF

| Method | Permanent in SIF? |
|--------|-------------------|
| `export FOO=bar` in your host shell | No |
| `APPTAINERENV_FOO=bar apptainer exec ...` | No (host inject) |
| `/.singularity.d/env/99-*.sh` or `%environment` | Yes |

Also avoid relying only on `/etc/bash.bashrc` — `apptainer exec` often does not start a login bash, so `/.singularity.d/env/` is the reliable place.

## Quick verify

```bash
apptainer exec $ENV_DIR/your.sif bash -lc 'echo $TORCH_EXTENSIONS_DIR'
```

---

**User**

After having done this when I execute the apptainer shell with 
apptainer shell --nv <xyz>.sif

I run into the following read_only file system error for my knn_cuda library. 
OSError: [Errno 30] Read-only file system: '/opt/venv/lib/python3.10/site-packages/knn_cuda/csrc/_ext/knn/lock'

What can i do to fix this?

---

**Cursor**

This is the package trying to write into the SIF’s read-only `/opt/venv`. I’ll check how `knn_cuda` builds/locks in your setup.

`knn_cuda` is not using `TORCH_EXTENSIONS_DIR`. On import it JIT-builds into its own install tree:

```10:34:/home/hpc/v114be/v114be10/projects/superdec/libs/KNN_CUDA/knn_cuda/__init__.py
def load_cpp_ext(ext_name):
    ...
    ext_path = os.path.join(ext_csrc, "_ext", ext_name)
    os.makedirs(ext_path, exist_ok=True)
    ...
    ext = load(
        name=ext_name,
        ...
        build_directory=ext_path,  # <- inside /opt/venv/.../site-packages
        ...
    )
```

A normal SIF is read-only, so creating `.../knn/lock` fails with errno 30. Prebuilding the `.so` alone often still fails, because PyTorch still opens that lock file.

## Fixes (pick one)

### 1. Easiest runtime fix: `--writable-tmpfs`

```bash
apptainer shell --nv --writable-tmpfs <xyz>.sif
# or
apptainer exec --nv --writable-tmpfs <xyz>.sif python ...
```

Writes go to a tmpfs overlay; good for interactive use. For Slurm, add the same flag to `apptainer_wrapper.sh`.

### 2. Better permanent fix: point build dir somewhere writable

Patch `knn_cuda` (or install a fork) so `build_directory` is not under `/opt/venv`, e.g.:

```python
build_directory = os.path.join(
    os.environ.get("TORCH_EXTENSIONS_DIR", "/tmp/torch_extensions"),
    "knn_cuda",
    ext_name,
)
```

Then set the env var to a **writable** path, not `/opt/...`:

```sh
export TORCH_EXTENSIONS_DIR="${TMPDIR:-/tmp}/torch_extensions_${USER}"
```

`/opt/torch_extensions` inside the SIF is also read-only, so the env var you just baked in will hit the same class of error for `_pvcnn_backend`.

### 3. Bind a writable dir over the knn build path

```bash
mkdir -p $TMPDIR/knn_ext
apptainer shell --nv \
  -B $TMPDIR/knn_ext:/opt/venv/lib/python3.10/site-packages/knn_cuda/csrc/_ext/knn \
  <xyz>.sif
```

### 4. Prebuild inside writable sandbox, then still use a writable overlay at runtime

Useful so the first import is fast, but you still need (1), (2), or (3) because of the lock file.

---

**Practical recommendation:** use `--writable-tmpfs` (or fix `knn_cuda`’s `build_directory`) for runs, and change `TORCH_EXTENSIONS_DIR` from `/opt/torch_extensions` to something under `$TMPDIR` or `$HOME/.cache`.

