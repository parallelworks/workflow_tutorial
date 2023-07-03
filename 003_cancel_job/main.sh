#!/bin/bash
source inputs.sh

if [ -z "${chdir}" ]; then
    chdir=${resource_1_workdir}
fi

sshcmd="ssh -o StrictHostKeyChecking=no ${resource_1_username}@${resource_1_publicIp}"

echo; echo "Writing SLURM script <demo.sbatch>"
cat >> demo.sbatch <<HERE
#!/bin/bash
#SBATCH --job-name=demo
#SBATCH --ntasks-per-node=1
#SBATCH --time=00:05:00
#SBATCH --chdir=${chdir}
${command}
HERE
chmod +x demo.sbatch
cat demo.sbatch

echo; echo "Creating remote directory <${resource_1_username}@${resource_1_publicIp}:${chdir}"
${sshcmd} "mkdir -p ${chdir}"

echo; echo "Copying SLURM script <demo.sbatch> to <${resource_1_username}@${resource_1_publicIp}:${chdir}/>"
scp demo.sbatch ${resource_1_username}@${resource_1_publicIp}:${chdir}/

echo; echo "Submiting SLURM job with command <${sshcmd} \"sbatch ${chdir}/demo.sbatch\">"
slurm_job=$($sshcmd "sbatch ${chdir}/demo.sbatch" | tail -1 | awk -F ' ' '{print $4}')

echo; echo "Creating kill script"
cat >> kill.sh <<HERE
$sshcmd "scancel ${slurm_job}"
HERE
chmod +x kill.sh
cat kill.sh

echo; echo "Monitoring job <${slurm_job}>"
while true; do
    sj_status=$($sshcmd squeue -j ${slurm_job} | tail -n+2 | awk '{print $5}')
    echo "    $(date): Status ${sj_status}"
    if [ -z "${sj_status}" ]; then
        # Job is no longer running
        sj_status=$($sshcmd sacct -j ${slurm_job}  --format=state | tail -n1 | tr -d ' ')
        if [[ "${sj_status}" == "FAILED" ]]; then
            echo "ERROR: SLURM job <${slurm_job}> failed"
            exit 1
        else
            exit 0
        fi
    fi
    sleep 20
done