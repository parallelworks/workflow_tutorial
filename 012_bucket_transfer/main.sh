#!/bin/bash

"""
1. Sets up environment variables and sources necessary scripts.
2. Constructs an SSH command to connect to the remote resource.
3. Determines the job directory paths for both local and remote environments.
4. Creates a run script `run.sh` with specified directives, inputs, and bucket command.
5. Transfers the run script to the job directory on the remote cluster using SCP.
5. Submits the job to the controller node of the cluster or to its SLURM partition or PBS queue, 
   depending on the specified scheduler type.
6. Optionally waits for the job to complete and cancels it if necessary.
"""

APP_DIR=$(dirname $0) # This is an absolute path!

source ${APP_DIR}/libs.sh
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
# Create job directory in cluster
${sshcmd} mkdir -p ${CLUSTER_JOB_DIR}

echo; echo; echo "CREATING RUN SCRIPT"
"""
#!/bin/bash
-----------
SLURM / PBS directives (optional)
-----------
Inputs from inputs.sh
-----------
Load bucket name and short-term credentials
-----------
Command
"""

echo '#!/bin/bash' >> run.sh
echo -e ${scheduler_directives} >> run.sh
cat inputs.sh >> run.sh
echo "token_generator_path=${APP_DIR}/bucket_token_generator.py" >> run.sh
cat ${APP_DIR}/load_bucket_credentials.sh >> run.sh
echo ${bucket_command} >> run.sh
chmod +x run.sh 
cat run.sh

echo; echo; echo "TRANSFERRING RUN SCRIPT TO JOB DIRECTORY IN CLUSTER ${resource_username}@${resource_publicIp}"
scp run.sh ${resource_username}@${resource_publicIp}:${CLUSTER_JOB_DIR}

echo; echo; echo "RUNNING JOB IN CLUSTER ${resource_username}@${resource_publicIp}"
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
    echo; echo; echo "WAITING FOR JOB ${jobid}"
    # Write cancel script to remove/cancel the submitted job from the queue if the pw job is canceled
    echo "#!/bin/bash" > cancel.sh
    echo "${sshcmd} ${cancel_cmd} ${jobid}" >> cancel.sh
    chmod +x cancel.sh
    # Wait for submitted job to complete before exiting pw job
    wait_job
    # Make sure job is canceled before exiting the workflow
    ./cancel.sh
fi