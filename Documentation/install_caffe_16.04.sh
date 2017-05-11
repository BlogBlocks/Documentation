#!/bin/bash

set -v
NUMBER_OF_CORES=2

apt-get update  
apt-get -y install locate \
make \
nano \
cmake \
git \
curl \
gcc-4.6 build-essential \
python-dev \
python-pip \
liblmdb-dev \
libhdf5-serial-dev \
libleveldb-dev libsnappy-dev \
libopencv-dev \
libprotobuf-dev \
protobuf-compiler \
--no-install-recommends libboost-all-dev  
libgflags-dev \
libgoogle-glog-dev \
libatlas-base-dev \
pip install --upgrade pip \
pip install numpy \
pip install -U setuptools 

git clone https://github.com/BVLC/caffe.git Caffe  
cd Caffe  
cd python
for req in $(cat requirements.txt); do pip install $req; done
echo "export PYTHONPATH=$(pwd):$PYTHONPATH " >> ~/.bash_profile 
source ~/.bash_profile 
cd ..
echo "INCLUDE_DIRS += /usr/include/hdf5/serial" >> Makefile.config
echo "LIBRARY_DIRS += /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/hdf5/serial" >> Makefile.config
echo "PYTHON_INCLUDE := /usr/local/lib/python2.7/dist-packages/numpy/core/include /usr/local/lib/python2.7/dist-packages/numpy/core/include/numpy" >> Makefile.config
# Compile caffe and pycaffe
cp Makefile.config.example Makefile.config
sed -i '8s/.*/CPU_ONLY := 1/' Makefile.config # Line 8: CPU only
apt-get -y install -y libopenblas-dev
sed -i '33s/.*/BLAS := open/' Makefile.config
find . -type f -exec sed -i -e 's^"hdf5.h"^"hdf5/serial/hdf5.h"^g' -e 's^"hdf5_hl.h"^"hdf5/serial/hdf5_hl.h"^g' '{}' \;
cd /usr/lib/x86_64-linux-gnu
sudo ln -s libhdf5_serial.so.8.0.2 libhdf5.so
sudo ln -s libhdf5_serial_hl.so.8.0.2 libhdf5_hl.so
cd /Caffe
 # Line 33: to use OpenBLAS
# Note that if one day the Makefile.config changes and these line numbers change, we're screwed
# Maybe it would be best to simply append those changes at the end of Makefile.config 
echo "export OPENBLAS_NUM_THREADS=($NUMBER_OF_CORES)" >> ~/.bash_profile 

mkdir build
cd build
cmake ..
cd ..
make all -j$NUMBER_OF_CORES # 4 is the number of parallel threads for compilation: typically equal to number of physical cores
for requirement in $(cat ./python/requirements.txt); do  
    pip install $requirement
done  
make pycaffe  -j$NUMBER_OF_CORES
make test
make runtest
#make matcaffe
make distribute
mkdir /usr/local/caffe
cp -ar /scripts/Caffe/distribute /usr/local/caffe  
if [[ -z $(cat ~/.bashrc | grep /usr/local/caffe/bin) ]] ; then  
    echo -e "\n# Adds Caffe to the PATH variable" >> ~/.bashrc
    echo "export PATH=\$PATH:/usr/local/caffe/bin" >> ~/.bashrc
    echo "export CPATH=\$CPATH:/usr/local/caffe/include" >> ~/.bashrc
    echo "export PYTHONPATH=\$PYTHONPATH:/usr/local/caffe/python" >> ~/.bashrc
    echo "export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:/usr/local/caffe/lib" >> ~/.bashrc
    source ~/.bashrc

updatedb
fi  
