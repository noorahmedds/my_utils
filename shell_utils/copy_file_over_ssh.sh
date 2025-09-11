# Copying from local to remote
scp ./Cap3D+Qwen_Qwen2.5-0.5B.zip b266be11@alex:/home/atuin/b266be/b266be11/datasets

# Copy from remote to local (run on local)
scp -r alex.nhr.fau.de:~/projects/tell2script/runs tell2script/

# With skipping
rsync -av --ignore-existing *.zip b266be11@helma:/hnvme/workspace/b266be11-tell2script/datasets/ShapeNetCaptions/