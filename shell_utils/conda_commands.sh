conda env create --name <my_env_name> -f environment.yml # with the environment yaml

# Or update an already create conda env to install the env yaml
conda env update --name myenv --file environment.yml

# Export the python libs in the old conda env with this
conda env export > environment.yml

# Create conda env in a certain directory. Ref:https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html
conda create --prefix ${ENV_DIR}/software/private/conda/envs/superdec_p3_11 python=3.11

# Conda remove env
conda remove --all -n superdec_p3_11