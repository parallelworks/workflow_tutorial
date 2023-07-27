#!/bin/bash

# Required variables
UCONTAINER_JOB_DIR=__UCONTAINER_JOB_DIR__
CLUSTER_JOB_DIR=__CLUSTER_JOB_DIR__
CONTROLLER_INTERNAL_IP=__CONTROLLER_INTERNAL_IP__

# Change directory to the run directory
mkdir -p ${CLUSTER_JOB_DIR}
cd ${CLUSTER_JOB_DIR}

####################################
# COMPUTE NODE INITIATES TRANSFERS #
####################################
# The compute runs the rsync command

# USER CONTAINER ---> COMPUTE NODE
# First, let's transfer a directory from the user container 
# to the compute node of the cluster

origin="usercontainer:${UCONTAINER_JOB_DIR}/transfer-directory/"
destination="compute-transfer-to-compute-from-usercontainer/"

echo; echo "Transferring directory from ${origin} to ${destination}"
rsync -avzq -e "ssh -J ${CONTROLLER_INTERNAL_IP}" --rsync-path="mkdir -p ${UCONTAINER_JOB_DIR} && rsync" ${origin} ${destination}

echo "Hello from the compute node $(hostname)" > ${destination}/greetings.txt

# COMPUTE NODE ---> USER CONTAINER
# Then let's transfer the directory from the compute node of
# the cluster to the user container
origin="compute-transfer-to-compute-from-usercontainer/"
destination="usercontainer:${UCONTAINER_JOB_DIR}/compute-transfer-to-usercontainer-from-compute/"

echo; echo "Transferring directory from ${origin} to ${destination}"
rsync -avzq -e "ssh -J ${CONTROLLER_INTERNAL_IP}" ${origin} ${destination}