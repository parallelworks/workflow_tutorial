#!/bin/bash
######################################
# USER CONTAINER INITIATES TRANSFERS #
######################################
# The user container runs the rsync command

# USER CONTAINER ---> CONTROLLER NODE
# First, let's transfer a directory from the user container 
# to the controller node of the cluster

origin=transfer-directory/
destination=${resource_1_username}@${resource_1_publicIp}:${CLUSTER_JOB_DIR}/usercontainer-transfer-to-controller-from-usercontainer/

echo; echo "User container is transferring the directory from ${origin} to ${destination}"
rsync -avzq --rsync-path="mkdir -p ${CLUSTER_JOB_DIR} && rsync" ${origin} ${destination}

# CONTROLLER NODE ---> USER CONTAINER
# Then let's transfer the directory from the controller node of
# the cluster to the user container
origin=${resource_1_username}@${resource_1_publicIp}:${CLUSTER_JOB_DIR}/usercontainer-transfer-to-controller-from-usercontainer/
destination=./usercontainer-transfer-to-usercontainer-from-controller/

echo; echo "User container is transferring the directory from ${origin} to ${destination}"
rsync -avzq ${origin} ${destination}