# Often this can happen because of arch mismatch. To fix this,
# you need to set the TORCH_CUDA_ARCH_LIST environment variable to the correct architecture.
# And rebuild after deleting the build directory.

# Example: Install pointops for MaskPoint on a GPU with compute capability 9.0
export TORCH_CUDA_ARCH_LIST="7.5;8.0;8.6;9.0"
cd /home/hpc/v114be/v114be10/projects/superdec/libs/MaskPoint/extensions/pointops
rm -rf build dist *.egg-info
python setup.py install