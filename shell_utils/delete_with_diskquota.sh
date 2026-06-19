#  If your disk quota is full, you can delete files with the following command

# This will move the file to the tmp directory and then delete it.
mv <file_to_delete> /tmp/
rm -rf /tmp/<file_to_delete>

# Truncate a file (make it empty, but keep the file):
find . -maxdepth 1 -type f -size +500M -exec sh -c ': > "$1"' sh {} \; -quit