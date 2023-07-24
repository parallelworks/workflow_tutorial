#!/bin/bash
# Load  workflow parameter names and values from the XML as environment variables
# In this case: command, resource_1_username, resource_1_publicIp
source inputs.sh
# Load auxiliarie funcions and variables
source libs.sh

# JOBID=<workflow-name>-<job-number>
export PW_JOB_ID=$(pwd | rev | cut -d'/' -f1-2 | rev | tr '/' '-')

if [[ ${input_method} == "TEXT" ]]; then
    # WRITE SCRIPT
    # Path to the script in the user workspace
    workspace_script_path="${PWD}/script.sh"
    echo "Writing script to ${workspace_script_path}"
    echo -e ${script_text} > ${workspace_script_path}
    chmod +x ${workspace_script_path}
fi

if [[ ${input_method} == "TEXT" ]] || [[ ${input_method} == "WORKSPACE_PATH" ]]; then
    # TRANSFER SCRIPT TO CLUSTER
    # Path to the script in the cluster
    echo "Transferring script ${workspace_script_path} to ${resource_username}@${resource_publicIp}:${cluster_script_path}"
    cluster_script_path=${resource_workdir}/script-${JOB-ID}.sh
    scp ${workspace_script_path} ${resource_username}@${resource_publicIp}:${cluster_script_path}
fi

# SUBMIT JOB
if [[ ${jobschedulertype} == "SLURM" ]]; then
    submit_cmd="sbatch"
    cancel_cmd="scancel"
    status_cmd="squeue" 
    # Submit job to SLURM partition and save jobid
    export jobid=$(${sshcmd} ${submit_cmd} ${cluster_script_path} | tail -1 | awk -F ' ' '{print $4}')
elif [[ ${jobschedulertype} == "PBS" ]]; then
    submit_cmd="qsub"
    cancel_cmd="qdel"
    status_cmd="qstat"
    # Submit job to PBS queue and save jobid
    export jobid=$(${sshcmd} ${submit_cmd} ${cluster_script_path})
else
    # Run script directly in the controller/login node
    # This command runs a foreground process
    ${sshcmd} ${cluster_script_path}
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
