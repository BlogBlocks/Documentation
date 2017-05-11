#!/bin/bash

set -v
NUMBER_OF_CORES=2

apt-get -y update  
apt-get -y install locate
apt-get -y install make
apt-get -y install nano
apt-get -y install cmake
apt-get -y install git  
apt-get -y install curl  
apt-get -y install gcc-4.6 build-essential  
apt-get -y install python-dev  
apt-get -y install python-pip  
pip install --upgrade pip  
pip install numpy  
apt-get -y install liblmdb-dev  
apt-get -y install libhdf5-serial-dev  
apt-get -y install libleveldb-dev libsnappy-dev  
apt-get -y install libopencv-dev  
apt-get -y install libprotobuf-dev  
apt-get -y install protobuf-compiler  
apt-get -y install --no-install-recommends libboost-all-dev  
apt-get -y install libgflags-dev  
apt-get -y install libgoogle-glog-dev  
apt-get -y install libatlas-base-dev  
git clone https://github.com/BVLC/caffe.git Caffe  
cd Caffe  


# Prepare Python binding (pycaffe)
cd python
for req in $(cat requirements.txt); do pip install $req; done
echo "export PYTHONPATH=$(pwd):$PYTHONPATH " >> ~/.bash_profile # to be able to call "import caffe" from Python after reboot
source ~/.bash_profile # Update shell 
cd ..
echo "INCLUDE_DIRS += /usr/include/hdf5/serial" >> Makefile.config
echo "LIBRARY_DIRS += /usr/lib/x86_64-linux-gnu /usr/lib/x86_64-linux-gnu/hdf5/serial" >> Makefile.config
echo "PYTHON_INCLUDE := /usr/local/lib/python2.7/dist-packages/numpy/core/include /usr/local/lib/python2.7/dist-packages/numpy/core/include/numpy" >> Makefile.config
# Compile caffe and pycaffe
cp Makefile.config.example Makefile.config
sed -i '8s/.*/CPU_ONLY := 1/' Makefile.config # Line 8: CPU only
apt-get -y install -y libopenblas-dev
sed -i '33s/.*/BLAS := open/' Makefile.config # Line 33: to use OpenBLAS
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
