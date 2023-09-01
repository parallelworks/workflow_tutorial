#!/bin/bash
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate

# Use the resource wrapper
python3 /swift-pw-bin/utils/input_form_resource_wrapper.py 

# Load  workflow parameter names and values from the XML as environment variables
# In this case: command, resource_1_username, resource_1_publicIp
source inputs.sh
# Load auxiliarie funcions and variables
APP_DIR=$(dirname $0)
source ${APP_DIR}/libs.sh

# JOBID=<workflow-name>-<job-number>
export PW_JOB_ID=$(pwd | rev | cut -d'/' -f1-2 | rev | tr '/' '-')

resource_labels=$(cat ${APP_DIR}/workflow.xml | grep section | grep -E 'pwrl_' |  awk -F "'" '{print $2}' | sed "s|pwrl_||g" )

echo "RESOURCE LABELS:"
echo ${resource_labels}
for rl in ${resource_labels}; do
    echo; echo "Resource Label: ${rl}"
    
    # Load resource inputs/data/info
    source resources/${rl}/inputs.sh

    export sshcmd="ssh -o StrictHostKeyChecking=no ${resource_publicIp}"

    if [[ ${input_method} == "TEXT" ]]; then
        script_text=$(cat resources/${rl}/inputs.json | grep script_text | awk -F': ' '{print $2}' | sed 's/[",]//g')
        # WRITE SCRIPT
        # Path to the script in the user workspace
        workspace_script_path="${PWD}/resources/${rl}/script-${rl}.sh"
        echo "Writing script to ${workspace_script_path}"
        echo -e ${script_text} > ${workspace_script_path}
        chmod +x ${workspace_script_path}
    fi

    if [[ ${input_method} == "TEXT" ]] || [[ ${input_method} == "WORKSPACE_PATH" ]]; then
        # TRANSFER SCRIPT TO RESOURCE
        # Path to the script in the resource
        ${sshcmd} "mkdir -p ${resource_workdir}"
        resource_script_path=${resource_workdir}/script-${rl}-${PW_JOB_ID}.sh
        echo "Transferring script ${workspace_script_path} to ${resource_publicIp}:${resource_script_path}"
        scp ${workspace_script_path} ${resource_publicIp}:${resource_script_path}
    fi

    # SUBMIT JOB
    if [[ ${jobschedulertype} == "SLURM" ]]; then 
        # Submit job to SLURM partition and save jobid
        export jobid=$(${sshcmd} ${submit_cmd} ${resource_script_path} | tail -1 | awk -F ' ' '{print $4}')
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        # Submit job to PBS queue and save jobid
        export jobid=$(${sshcmd} ${submit_cmd} ${resource_script_path})
    else
        # Run script directly in the controller/login node
        # This command runs a foreground process
        ${sshcmd} ${resource_script_path}
        # Exit script with the exit code of the above command
        exit $?
    fi
    echo "Submitted job ID: ${jobid}"

    # Write cancel script to remove/cancel the submitted job from the queue if the pw job is canceled
    echo "#!/bin/bash" > cancel.sh
    echo "${sshcmd} ${cancel_cmd} ${jobid}" >> cancel.sh
    chmod +x cancel.sh
    # Wait for job with timeout
    # - Exits main.sh if job is completed or fails
    # - Continues loop if job times out
    wait_job_timeout
    # Make sure job is canceled before exiting the workflow
    ./cancel.sh
done 

echo "The command timed out in all the resources"
exit 1
