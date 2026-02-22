# Remember that your nvcc version (System CUDA ToolKit) is only important when building from source
# If you are simply installing pytorch using pip. The pytorch wheel should come prepackaged with a cuda runtime.
# This version torch.version.cuda should remain compatible with other downloaded "CUDA extensions" (e.g. pytorch3d, torch-scatter) and so on
# This is because they use the same underlying cuda kernels that come packaged with the cuda-runtime (cuda shipped with pytorch)
# The nvcc version cuda toolkit is important when you would like to build a cuda-extension from source. This is rare and you should not usually have to do it
# Important to note that pip install from source builds an isolate env where pytorch may not be visible. It is important to use --no-build-isolation flag for such build from source situations

python3 -m venv pytorch3d_venv
source pytorch3d_venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install "numpy<2"

# Note the cuda run-time version here. Use this run time version alongside the correct pytorch, python, cpu arch, numpy version.
# pip install torch==2.0.1 torchvision==0.15.2 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu117
# pip install torch==2.1.0 torchvision==0.16.0 torchaudio==2.1.0 --index-url https://download.pytorch.org/whl/cu121
pip install torch==2.6.0 torchvision==0.21.0 torchaudio==2.6.0 --index-url https://download.pytorch.org/whl/cu124

pip install fvcore iopath
pip install pytorch3d -f https://dl.fbaipublicfiles.com/pytorch3d/packaging/wheels/py310_cu117_pyt201/download.html
# pip install "git+https://github.com/facebookresearch/pytorch3d.git@stable"
pip install torch_geometric
pip install pyg_lib torch_scatter torch_cluster torch_spline_conv -f https://data.pyg.org/whl/torch-2.0.1+cu117.html --no-cache-dir
pip install hydra-core
pip install -e .
pip install open3d transformers==4.40.2 sentence-transformers==2.7.0 geomloss

# Installing opencv
apt install -y libglib2.0-0
pip install opencv-python --no-deps # not --no-deps forces pip not to resolve updates which could update numpy

# Other build related error
# pip install wheel # in case running into bdist_wheel error during compilation
# --no-build-isolation if torch not installed error

# ----- Common Errors and how to Resolve them -----
# When installing pointnet2_ops_libs you may run into version ninja compile erorrs. 
# For me this was solved by reverting to 11.8 CUDA


# if you run into the error [nvcc fatal : Unsupported gpu architecture 'compute_90']. 
# This is usually referring to your cuda toolkit not being compatible with the architecture of your GPU
# A cuda-toolkit (nvcc) knows by default some architectures, for example (nvcc knows upuntil sm_86(or 8.6), sm_50->sm_87)
# when compiling for a more recent sm_90 compute capability your nvcc may fail raising the nvcc fatal error. 
# to fix this you need to explicitly define the torch cuda arch list for nvcc to use when compiling cuda extensions
export TORCH_CUDA_ARCH_LIST="8.6;8.0;7.5" #os.environ['TORCH_CUDA_ARCH_LIST'] = "8.6;8.0;7.5"