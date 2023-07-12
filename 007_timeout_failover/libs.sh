#!/bin/bash

# FIXME: Support failure as well?
wait_job_timeout() {
    end_time=$((SECONDS + max_time))
    while [[ $SECONDS -lt $end_time ]]; do
        # squeue won't give you status of jobs that are not running or waiting to run
        # qstat returns the status of all recent jobs
        job_status=$($sshcmd ${status_cmd} | grep ${jobid} | awk '{print $5}')
        if [[ ${jobschedulertype} == "SLURM" ]]; then
            # If job status is empty job is no longer running
            if [ -z ${job_status} ]; then
                job_status=$($sshcmd sacct -j ${jobid}  --format=state | tail -n1)
                echo "    Job ${jobid} exited with status ${job_status}"
                exit 0
            fi
        elif [[ ${jobschedulertype} == "PBS" ]]; then
            if [[ ${job_status} == "C" ]]; then
                echo "Job ${jobid} exited with status C"
                exit 0
            fi
            if [ -z ${job_status} ]; then
                echo "Job ${jobid} exited"
                exit 0
            fi
        fi
        echo "    Job ${jobid} status: ${job_status}"
        sleep 5
    done
}
