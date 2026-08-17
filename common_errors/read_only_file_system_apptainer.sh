# When running apptainer in non-writable mode, you may run into the following error:
# To fix this you can run the following command:
apptainer exec --nv --writable-tmpfs $ENV_DIR/${env_name} ${run_command[@]}