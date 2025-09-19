tar -cf - <folder> | pigz -9 > <folder>.tar.gz 
pigz -dc ${SUPERDEC_STORAGE}/datasets/shapenet.tar.gz | tar -xf - -C ./

# Zipping
zip -r folders.zip folder_1
unzip folders.zip -d <folder_path>