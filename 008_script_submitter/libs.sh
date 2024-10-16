#!/bin/bash



get_slurm_job_status() {
    # Get the header line to determine the column index corresponding to the job status
    if [ -z "${SQUEUE_HEADER}" ]; then
        export SQUEUE_HEADER="$(eval "$sshcmd squeue" | awk 'NR==1')"
    fi
    status_column=$(echo "${SQUEUE_HEADER}" | awk '{ for (i=1; i<=NF; i++) if ($i ~ /^S/) { print i; exit } }')
    status_response=$(eval $sshcmd squeue | grep "\<${jobid}\>")
    echo "${SQUEUE_HEADER}"
    echo "${status_response}"
    export job_status=$(echo ${status_response} | awk -v id="${jobid}" -v col="$status_column" '{print $col}')
}

get_pbs_job_status() {
    # Get the header line to determine the column index corresponding to the job status
    if [ -z "${QSTAT_HEADER}" ]; then
        export QSTAT_HEADER="$(eval "$sshcmd qstat" | awk 'NR==1')"
    fi
    status_response=$(eval $sshcmd qstat 2>/dev/null | grep "\<${jobid}\>")
    echo "${QSTAT_HEADER}"
    echo "${status_response}"
    export job_status="$(eval $sshcmd qstat -f ${jobid} 2>/dev/null  | grep job_state | cut -d'=' -f2 | tr -d ' ')"

}


# FIXME: Support failure as well?
wait_job() {
    while true; do
        sleep 15
        # squeue won't give you status of jobs that are not running or waiting to run
        # qstat returns the status of all recent jobs
        if [[ ${jobschedulertype} == "SLURM" ]]; then
            get_slurm_job_status
            # If job status is empty job is no longer running
            if [ -z "${job_status}" ]; then
                job_status=$($sshcmd sacct -j ${jobid}  --format=state | tail -n1)
                break
            fi
        elif [[ ${jobschedulertype} == "PBS" ]]; then
            get_pbs_job_status
            if [[ "${job_status}" == "C" ]]; then
                break
            elif [ -z "${job_status}" ]; then
                break
            fi
        fi
    done
}