#!/bin/bash
# Load  workflow parameter names and values from the XML as environment variables
# In this case: command, resource_1_username, resource_1_publicIp
source inputs.sh
# Load auxiliarie funcions and variables
APP_DIR=$(dirname $0)
source ${APP_DIR}/libs.sh

export sshcmd="ssh -o StrictHostKeyChecking=no ${resource_username}@${resource_publicIp}"

# JOBID=<workflow-name>-<job-number>
export PW_JOB_ID=$(pwd | rev | cut -d'/' -f1-2 | rev | tr '/' '-')

if [[ ${input_method} == "TEXT" ]]; then
    # WRITE SCRIPT
    # Path to the script in the user workspace
    workspace_script_path="${PWD}/script.sh"
    echo "Writing script to ${workspace_script_path}"
    jq -r '.script_text' inputs.json | sed 's/\\n/\n/g' > ${workspace_script_path}
    chmod +x ${workspace_script_path}
fi

if [[ ${input_method} == "TEXT" ]] || [[ ${input_method} == "WORKSPACE_PATH" ]]; then
    # TRANSFER SCRIPT TO RESOURCE
    # Path to the script in the resource
    resource_script_path=${resource_workdir}/script-${PW_JOB_ID}.sh
    echo "Transferring script ${workspace_script_path} to ${resource_username}@${resource_publicIp}:${resource_script_path}"
    scp ${workspace_script_path} ${resource_username}@${resource_publicIp}:${resource_script_path}
fi

# SUBMIT JOB
echo; echo "Submitting job"
if [[ ${jobschedulertype} == "SLURM" ]]; then
    check_slurm
    submit_cmd="sbatch"
    cancel_cmd="scancel"
    status_cmd="squeue" 
    # Submit job to SLURM partition and save jobid
    echo "${sshcmd} ${submit_cmd} ${resource_script_path}"
    export jobid=$(${sshcmd} ${submit_cmd} ${resource_script_path} | tail -1 | awk -F ' ' '{print $4}')
elif [[ ${jobschedulertype} == "PBS" ]]; then
    submit_cmd="qsub"
    cancel_cmd="qdel"
    status_cmd="qstat"
    # Submit job to PBS queue and save jobid
    echo "${sshcmd} ${submit_cmd} ${resource_script_path}"
    export jobid=$(${sshcmd} ${submit_cmd} ${resource_script_path})
else
    # Run script directly in the controller/login node
    # This command runs a foreground process
    ${sshcmd} ${resource_script_path}
    # Exit script with the exit code of the above command
    exit $?
fi

if [[ -z ${jobid} ]]; then
    echo; echo;
    echo "Failed to submit job to the scheduler with command:"
    echo "${sshcmd} ${submit_cmd} ${resource_script_path}"
    echo; echo "Exiting workflow."
    exit 1
fi

echo; echo "Submitted job ID: ${jobid}"

if [[ ${wait_for_job} == "true" ]] || [[ ${wait_for_job} == "Yes" ]]; then
    # Write cancel script to remove/cancel the submitted job from the queue if the pw job is canceled
    echo "#!/bin/bash" > cancel.sh
    echo "${sshcmd} ${cancel_cmd} ${jobid}" >> cancel.sh
    chmod +x cancel.sh
    if [[ ${jobschedulertype} == "SLURM" ]]; then
        log_file_paths=$(${sshcmd} scontrol show job ${jobid} | grep -E "StdOut|StdErr" | awk -F= '{print $2}' | uniq)
    fi
    # Wait for submitted job to complete before exiting pw job
    wait_job
    # Make sure job is canceled before exiting the workflow
    ./cancel.sh

    if [[ ${jobschedulertype} == "SLURM" ]]; then
        print_slurm_logs "${log_file_paths}"
    fi

fi
