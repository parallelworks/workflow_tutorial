#!/bin/bash

# Required variables
UCONTAINER_JOB_DIR=__UCONTAINER_JOB_DIR__
CLUSTER_JOB_DIR=__CLUSTER_JOB_DIR__

# Change directory to the run directory
mkdir -p ${CLUSTER_JOB_DIR}
cd ${CLUSTER_JOB_DIR}

#######################################
# CONTROLLER NODE INITIATES TRANSFERS #
#######################################
# The controller runs the rsync command

# USER CONTAINER ---> CONTROLLER NODE
# First, let's transfer a directory from the user container 
# to the controller node of the cluster

origin="usercontainer:${UCONTAINER_JOB_DIR}/transfer-directory/"
destination="controller-transfer-to-controller-from-usercontainer/"

echo; echo "Transferring directory from ${origin} to ${destination}"
rsync -avzq --rsync-path="mkdir -p ${UCONTAINER_JOB_DIR} && rsync" ${origin} ${destination}

echo "Hello from the controller node $(hostname)" > ${destination}/greetings.txt

# CONTROLLER NODE ---> USER CONTAINER
# Then let's transfer the directory from the controller node of
# the cluster to the user container
origin="controller-transfer-to-controller-from-usercontainer/"
destination="usercontainer:${UCONTAINER_JOB_DIR}/controller-transfer-to-usercontainer-from-controller/"

echo; echo "Transferring directory from ${origin} to ${destination}"
rsync -avzq ${origin} ${destination}