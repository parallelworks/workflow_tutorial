#!/bin/bash
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate

python3 /swift-pw-bin/utils/input_form_resource_wrapper.py 

source inputs.sh
source libs.sh

app_dir=$(dirname $0)

resource_labels=$(cat ${app_dir}/workflow.xml | grep section | grep -E 'pwrl_' |  awk -F "'" '{print $2}' | sed "s|pwrl_||g" )
echo "RESOURCE LABELS:"
echo ${resource_labels}
for rl in ${resource_labels}; do
    echo; echo "Resource Label: ${rl}"
    
    # Load resource inputs/data/info
    source resources/${rl}/inputs.sh
    export sshcmd="ssh  -o StrictHostKeyChecking=no ${resource_publicIp}"

    # Write submit script
    header_sh=${PWD}/resources/${rl}/batch_header.sh
    submit_sh=${PWD}/resources/${rl}/submit.sh
    cp ${header_sh} ${submit_sh}

    if [[ "${resource_type}" == "slurmshv2" ]]; then
        echo "bash ${resource_workdir}/pw/.pw/remote.sh" >> ${submit_sh}
    fi
    echo ${command} >> ${submit_sh}

    # Create remote job directory
    remote_submit_sh=${resource_jobdir}/submit.sh    
    ${sshcmd} "mkdir -p ${resource_jobdir}"
    scp ${submit_sh} ${resource_publicIp}:${remote_submit_sh}

    # Submit job
    if [[ ${jobschedulertype} == "SLURM" ]]; then
        export jobid=$(${sshcmd} ${submit_cmd} ${remote_submit_sh} | tail -1 | awk -F ' ' '{print $4}')
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        export jobid=$(${sshcmd} ${submit_cmd} ${remote_submit_sh})
    fi

    if ! [ -z ${jobid} ]; then
        # Create kill script
        echo "${sshcmd} ${cancel_cmd} ${jobid}" > kill.sh
        # Wait for job with timeout
        # - Exits main.sh if job is completed or fails
        # - Continues loop if job times out
        wait_job_timeout
        # Kill timeout job
        bash kill.sh
    else
        echo "Job submission failed"
    fi
done 

echo "The command timed out in all the resources"
exit 1
