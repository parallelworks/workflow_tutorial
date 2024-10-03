#!/bin/bash

# Check if MPI is already installed
if [ -f "pw/load-intel-oneapi-mpi.sh" ]; then
    echo "Intel-OneAPI-MPI is already installed"
    exit 0
fi

# Clone the repository, download spack, setup modules
code_repo=https://github.com/jlinpw/intel-benchmarks
mkdir -p pw
cd pw
git clone ${code_repo}
git clone -c feature.manyFiles=true https://github.com/spack/spack.git
. $HOME/pw/spack/share/spack/setup-env.sh
spack install intel-oneapi-mpi intel-oneapi-compilers gcc-runtime
source /usr/share/lmod/8.7.7/init/bash
yes | spack module lmod refresh gcc-runtime intel-oneapi-mpi intel-oneapi-compilers

# Create file to load the environment
cat > load-intel-oneapi-mpi.sh <<HERE
#!/bin/bash
. $HOME/pw/spack/share/spack/setup-env.sh
spack load intel-oneapi-compilers@2024.2.1  intel-oneapi-mpi@2021.13.1
HERE
