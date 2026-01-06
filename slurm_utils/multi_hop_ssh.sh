# Use this for viser demoing-as well

# Ran from local. Already have ran the server on an salloc node
ssh -L 9999:<h12-07/compute-node-name>:9999 b266be11@<cluster_name/host_name>

# Note: VSCode automatically forwards a port to your local machine which is pretty annoying an doesn't work. Delete the forwarded node from the "PORTS" tab when you run in vscode shell