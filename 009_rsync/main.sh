#!/bin/bash
# This script demonstrates transferring files between the user container
# and the controller and compute nodes of a cluster using rsync. Depending
# on the files origin and destion and which node runs the rsync command
# we demonstrate the following scenarios
# 1. rsync runs in the user container
# 1.1 Directory is transferred from the user container to the controller node
# 1.2 Directory is transferred from the controller node to the user container
# 2. rsync runs in the controller node
# 2.1 Directory is transferred from the user container to the controller node
# 2.2 Directory is transferred from the controller node to the user container
# 3. rsync runs in the compute node
# 3.1 Directory is transferred from the user container to the compute node
# 3.2 Directory is transferred from the compute node to the user container


source inputs.sh
# JOB_DIR=<workflow-name>/<job-number>
# Absolute path to the job directory in the user space
export UCONTAINER_JOB_DIR=${PWD}
# Absolute path to the job directory in the remote resource
JOB_DIR=$(pwd | rev | cut -d'/' -f1-2 | rev)
export CLUSTER_JOB_DIR=${resource_1_workdir}/pw/${JOB_DIR}/

######################################
# USER CONTAINER INITIATES TRANSFERS #
######################################
# The user container runs the rsync command

echo; echo; echo "USER CONTAINER INITIATES TRANSFERS" 
bash usercontainer-runs-rsync.sh

#######################################
# CONTROLLER NODE INITIATES TRANSFERS #
#######################################
# The controller node runs the rsync command in the controller-runs-rsync.sh script

echo; echo; echo "CONTROLLER NODE INITIATES TRANSFERS" 

# Write the local and remote job directories to the controller-runs-rsync.sh
sed -i "s|__UCONTAINER_JOB_DIR__|${UCONTAINER_JOB_DIR}|g" controller-runs-rsync.sh
sed -i "s|__CLUSTER_JOB_DIR__|${CLUSTER_JOB_DIR}|g" controller-runs-rsync.sh

ssh ${resource_1_username}@${resource_1_publicIp} 'bash -s' < controller-runs-rsync.sh


####################################
# COMPUTE NODE INITIATES TRANSFERS #
####################################
# The compute node runs the rsync command in the compute-runs-rsync.sh script

echo; echo; echo "COMPUTE NODE INITIATES TRANSFERS" 

# Write the local and remote job directories to the compute-runs-rsync.sh
sed -i "s|__UCONTAINER_JOB_DIR__|${UCONTAINER_JOB_DIR}|g" compute-runs-rsync.sh
sed -i "s|__CLUSTER_JOB_DIR__|${CLUSTER_JOB_DIR}|g" compute-runs-rsync.sh
# Compute node needs to know the internal IP of the compute node to us as a jumphost
sed -i "s|__CONTROLLER_INTERNAL_IP__|${resource_1_privateIp}|g" compute-runs-rsync.sh

# Transfer the compute-runs-rsync.sh script to the controller node
rsync -avzq --rsync-path="mkdir -p ${CLUSTER_JOB_DIR} && rsync" compute-runs-rsync.sh ${resource_1_username}@${resource_1_publicIp}:${CLUSTER_JOB_DIR}/compute-runs-rsync.sh

ssh ${resource_1_username}@${resource_1_publicIp} srun bash ${CLUSTER_JOB_DIR}/compute-runs-rsync.sh

