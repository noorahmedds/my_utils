tar -cf - <folder> | pigz -9 > <folder>.tar.gz 
pigz -dc ${SUPERDEC_STORAGE}/datasets/shapenet.tar.gz | tar -xf - -C ./