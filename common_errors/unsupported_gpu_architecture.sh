# if you run into the error [nvcc fatal : Unsupported gpu architecture 'compute_90'|'sm_37']. 
# This is usually referring to your cuda toolkit not being compatible with the architecture of your GPU
# A cuda-toolkit (nvcc) knows by default some architectures, for example (nvcc knows upuntil sm_86(or 8.6), sm_50->sm_87)
# when compiling for a more recent sm_90 compute capability your nvcc may fail raising the nvcc fatal error. 
# to fix this you need to explicitly define the torch cuda arch list for nvcc to use when compiling cuda extensions
export TORCH_CUDA_ARCH_LIST="8.7;8.6;8.0;7.5" #os.environ['TORCH_CUDA_ARCH_LIST'] = "8.6;8.0;7.5"
