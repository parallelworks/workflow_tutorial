#!/bin/bash

get_job_status(){
    job_status=$($sshcmd ${status_cmd} | grep ${jobid} | awk '{print $5}')
    if [[ ${jobschedulertype} == "SLURM" ]]; then
        # If job status is empty job is no longer running
        if [ -z ${job_status} ]; then
            job_status=$($sshcmd sacct -j ${jobid}  --format=state | tail -n1)
            echo "    Job ${jobid} exited with status ${job_status}"
            if [[ "${job_status}" == *"FAILED"* ]]; then
                echo "ERROR: SLURM job [${slurm_job}] failed"
                return 2
            else
                return 1
            fi
        fi
    elif [[ ${jobschedulertype} == "PBS" ]]; then
        if [[ ${job_status} == "C" ]]; then
            echo "Job ${jobid} exited with status C"
            return 1
        fi
        if [ -z ${job_status} ]; then
            echo "Job ${jobid} exited"
            return 1
        fi
    fi
    return 0
}



wait_job_timeout() {
    end_time=$((SECONDS + max_time))
    while [[ $SECONDS -lt $end_time ]]; do
        get_job_status
        if [[ $? -eq 1 ]]; then
            exit 0
        elif [[ $? -eq 2 ]]; then
            # Break to resubmit to another resource
            # exit 1 to fail
            break
        fi
        echo "    Job ${jobid} status: ${job_status}"
        sleep 5
    done
}