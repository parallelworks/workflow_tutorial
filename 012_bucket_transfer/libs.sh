#!/bin/bash

get_job_status(){
    # Runs inside wait_job and wait_job_timeout
    job_status=$($sshcmd ${status_cmd} | awk -v id="${jobid}" '$1 == id {print $5}')
    if [[ ${jobschedulertype} == "SLURM" ]]; then
        # If job status is empty job is no longer running
        if [ -z "${job_status}" ]; then
            job_status=$($sshcmd sacct -j ${jobid}  --format=state | tail -n1)
            echo "    Job ${jobid} exited with status ${job_status}"
            if [[ "${job_status}" == *"FAILED"* ]]; then
                echo "ERROR: SLURM job [${jobid}] failed"
                return 2
            else
                return 1
            fi
        fi
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        if [[ "${job_status}" == "C" ]]; then
            echo "Job ${jobid} exited with status C"
            return 1
        fi
        if [ -z "${job_status}" ]; then
            echo "Job ${jobid} exited"
            return 1
        fi
    fi
    return 0
}

wait_job() {
    # DESCRIPTION:
    # Given a SLURM or PBS job id it waits for the job to finish.
    # REQUIRED ENVIRONMENT VARIABLES
    # 1. jobid: SLURM or PBS job id
    # 2. jobschedulertype: Scheduler type of the resource running the job. Must be SLURM or PBS.
    # 3. sshcmd: Command to ssh into the remote resource, e.g.: ssh -o StrictHostKeyChecking=no <user>@<external-ip>
    while true; do
        # squeue won't give you status of jobs that are not running or waiting to run
        # qstat returns the status of all recent jobs
        get_job_status
        ec=$?
        if [[ ${ec} -eq 1 ]]; then
            break
        elif [[ ${ec} -eq 2 ]]; then
            exit 1
        fi
        echo "    Job ${jobid} status: ${job_status}"
        sleep 5
    done
}