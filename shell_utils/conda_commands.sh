conda env create --name <my_env_name> -f environment.yml # with the environment yaml

# Or update an already create conda env to install the env yaml
conda env update --name myenv --file environment.yml

# Export the python libs in the old conda env with this
conda env export > environment.yml