# apptainer build --sandbox superdec_container docker://pytorch/pytorch

# apptainer shell --writable superdec_container

# Note the following env variable should be switched to a directory with the least load on it $APPTAINER_CACHEDIR. This is where the caches are kept


# # Build from definition file in a interactive shell
# apptainer build $TMPDIR/superdec_container.sif superdec_apptainer_conda.def

# # Test using this
# apptainer shell $TMPDIR/superdec_container.sif
# # Test with activating conda and so on

# # Run train file using this
# apptainer run $TMPDIR/superdec_container.sif <python command here>

# Execute with shell
cd ~/projects/superdec
apptainer build --sandbox $TMPDIR/pytorch_env docker://nvidia/cuda:13.0.1-cudnn-devel-ubuntu24.04
apptainer shell --nv --fakeroot --writable --no-home $TMPDIR/pytorch_env/

# Inside the apptainer shell, run the following commands
apt-get update && apt-get install -y python3 python3-pip python3-venv git unzip
apt-get clean
python3 -m venv /opt/venv
source /opt/venv/bin/activate
pip install --upgrade pip --no-cache-dir
pip install torch torchvision
pip install -r requirements.txt
pip install -e .
python setup_sampler.py build_ext --inplace
export SSL_CERT_FILE=${SUPERDEC_STORAGE}/certificates/cacert.pem

# SONATA Installation:
pip install spconv-cu${CUDA_VERSION}
pip install torch-scatter -f https://data.pyg.org/whl/torch-2.9.0+cu130.html --no-build-isolation
pip install git+https://github.com/Dao-AILab/flash-attention.git --no-build-isolation
pip install huggingface_hub timm

# With the following save the tmeporary env you created and save it as a portable sif file
apptainer build $ENV_DIR/pytorch.sif $TMPDIR/pytorch_env/

# You may use this to expand the sif to be in sandbox mode so you may write on it again
# apptainer build --sandbox $TMPDIR/pytorch_env $ENV_DIR/pytorch.sif && apptainer shell --nv --fakeroot --writable --no-home $TMPDIR/pytorch_env/
# apptainer build $ENV_DIR/pytorch.sif $TMPDIR/pytorch_env/   # Updated
# Follow this by building the .sif file again


### Run files using
# [Option #1] Non-interactive execution of the script with the following
apptainer exec --nv $ENV_DIR/pytorch.sif scripts/train_guide.sh

# [Option #2] Run an interactive shell
apptainer shell --nv $ENV_DIR/pytorch.sif # -> source /opt/venv/bin/activate
