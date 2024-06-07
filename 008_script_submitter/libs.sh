#!/bin/bash

# FIXME: Support failure as well?
wait_job() {
    while true; do
        # squeue won't give you status of jobs that are not running or waiting to run
        # qstat returns the status of all recent jobs
        job_status=$($sshcmd ${status_cmd} | grep ${jobid} | awk '{print $5}')
        if [[ ${jobschedulertype} == "SLURM" ]]; then
            # If job status is empty job is no longer running
            if [ -z "${job_status}" ]; then
                job_status=$($sshcmd sacct -j ${jobid}  --format=state | tail -n1)
                echo "    Job ${jobid} exited with status ${job_status}"
                if [[ "${job_status}" == *"FAILED"* ]]; then
                    echo "ERROR: SLURM job [${slurm_job}] failed"
                    exit 1
                else
                    break
                fi
            fi
        elif [[ ${jobschedulertype} == "PBS" ]]; then
            if [[ "${job_status}" == "C" ]]; then
                echo "Job ${jobid} exited with status C"
                break
            fi
            if [ -z "${job_status}" ]; then
                echo "Job ${jobid} exited"
                break
            fi
        fi
        echo "    Job ${jobid} status: ${job_status}"
        sleep 15
    done
}

check_slurm() {
    # Run ps command to check if slurmctld is running and exclude the grep process
    result=$(${sshcmd} ps aux | grep slurmctld | grep -v grep)

    # Check if the result is empty
    if [ -z "$result" ]; then
        echo "ERROR: slurmctld is not running in the selected resource ${resource_name}"
        echo "       Exiting workflow!"
        exit 1
    fi
}

# Function to print the SLURM logs
print_slurm_logs() {
    local log_file_paths=$1
    for log_file in ${log_file_paths}; do
        echo "${sshcmd} cat ${log_file}"
        ${sshcmd} cat ${log_file}
        echo
    done
}
