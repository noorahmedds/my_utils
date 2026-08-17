# RuntimeError: Error building extension '_pvcnn_backend': ninja: error: stat(/home/hpc/b266be/b266be11/projects/superdec/superdec/functional/src/voxelization/vox.cpp): Permission denied


# This can be caused by a carry over cache from a previous build potentially from a different user.
# When running in sandbox mode with --no-home, the cache is stored in the root directory.
# This has to be deleted before running the build again.

# Remove the cached build files
rm -rf /root/.cache/torch_extensions