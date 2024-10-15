#!/bin/bash
# This script automates the compilation and execution of an MPI 
# application on a remote cluster.It does the following steps:
# 1. Loads workflow parameters
# 2. Creates compilation and run scripts
# 3. Transfers requires files
# 4. Compiles on the cluster in the controller node of the cluster
# 5. Submits the job directly to the scheduler, to the SLURM partition or to the PBS queue
# 6. Optionally waits for job completion.

APP_DIR=$(dirname $0)
source ${APP_DIR}/libs.sh

# Load  workflow parameter names and values from the XML as environment variables
sed -i "s|__PW_USER__|${PW_USER}|g" inputs.sh
source inputs.sh

sshcmd="ssh -o StrictHostKeyChecking=no ${resource_username}@${resource_publicIp}"
echo "SSH command"
echo ${sshcmd}

# JOB_DIR=<workflow-name>/<job-number>
JOB_DIR=$(pwd | rev | cut -d'/' -f1-2 | rev)
# Absolute path to the job directory in the user space
export UCONTAINER_JOB_DIR=${PWD}
# Absolute path to the job directory in the remote resource
export CLUSTER_JOB_DIR=${resource_workdir}/pw/${JOB_DIR}/


if [[ ${install_mpi} == "true" ]]; then
    echo; echo; echo INSTALLING Intel-OneAPI-MPI
    ${sshcmd} 'bash -s' < ${APP_DIR}/install_intel_mpi_with_spack.sh
    load_mpi="source ${resource_workdir}/pw/software/load-intel-oneapi-mpi.sh"
fi

echo; echo; echo CREATING COMPILE SCRIPT
# Create compile script
cat > compile.sh <<HERE
#!/bin/bash
${load_mpi}
cd ${CLUSTER_JOB_DIR}
mpicc -o mpitest mpitest.c
chmod +x mpitest
HERE
cat compile.sh

echo; echo; echo CREATING RUN SCRIPT
echo -e ${scheduler_directives} > run.sh
cat >> run.sh <<HERE
${load_mpi}
cd ${CLUSTER_JOB_DIR}
mpirun -np ${np} ./mpitest &> mpitest.out
cat mpitest.out
HERE
chmod +x run.sh
cat run.sh

echo; echo; echo TRANSFERRING NECESSARY FILES TO CLUSTER
# Create remote directory
${sshcmd} mkdir -p ${CLUSTER_JOB_DIR}
scp ${APP_DIR}/mpitest.c run.sh ${resource_username}@${resource_publicIp}:${CLUSTER_JOB_DIR}

echo; echo; echo COMPILING APP
${sshcmd} 'bash -s' < compile.sh

echo; echo; echo RUNNING APP
# Path to run.sh in cluster
cluster_run_sh=${CLUSTER_JOB_DIR}/run.sh
# SUBMIT JOB
if [[ ${jobschedulertype} == "SLURM" ]]; then
    submit_cmd="sbatch"
    cancel_cmd="scancel"
    status_cmd="squeue" 
    # Submit job to SLURM partition and save jobid
    export jobid=$(${sshcmd} ${submit_cmd} ${cluster_run_sh} | tail -1 | awk -F ' ' '{print $4}')
elif [[ ${jobschedulertype} == "PBS" ]]; then
    submit_cmd="qsub"
    cancel_cmd="qdel"
    status_cmd="qstat"
    # Submit job to PBS queue and save jobid
    export jobid=$(${sshcmd} ${submit_cmd} ${cluster_run_sh})
else
    # Run script directly in the controller/login node
    # This command runs a foreground process
    ${sshcmd} ${cluster_run_sh}
    # Exit script with the exit code of the above command
    exit $?
fi
echo "Submitted job ID: ${jobid}"

if [[ ${wait_for_job} == "true" ]]; then
    # Write cancel script to remove/cancel the submitted job from the queue if the pw job is canceled
    echo "#!/bin/bash" > cancel.sh
    echo "${sshcmd} ${cancel_cmd} ${jobid}" >> cancel.sh
    chmod +x cancel.sh
    # Wait for submitted job to complete before exiting pw job
    wait_job
    # Make sure job is canceled before exiting the workflow
    ./cancel.sh
fi

echo; echo; echo PRINTING OUTPUT
echo "${sshcmd} cat ${CLUSTER_JOB_DIR}/mpitest.out"
${sshcmd} "cat ${CLUSTER_JOB_DIR}/mpitest.out"

