#!/bin/bash
APP_DIR=$(dirname $0)
source ${APP_DIR}/libs.sh

# Load  workflow parameter names and values from the XML as environment variables
source inputs.sh

sshcmd="ssh -o StrictHostKeyChecking=no ${resource_username}@${resource_publicIp}"
echo "SSH command"
echo ${sshcmd}

# JOB_DIR=<workflow-name>/<job-number>
JOB_DIR=$(pwd | rev | cut -d'/' -f1-2 | rev)
# Absolute path to the job directory in the remote resource
export CLUSTER_JOB_DIR=${resource_workdir}/pw/${JOB_DIR}/


if [[ ${install_mpi} == "true" ]]; then
    echo; echo; echo INSTALLING Intel-OneAPI-MPI
    ${sshcmd} 'bash -s' < ${APP_DIR}/install_intel_mpi_with_spack.sh
    load_mpi="source ${resource_workdir}/pw/load-intel-oneapi-mpi.sh"
fi
