## Script Submitter with Timeout and Failover
This workflow combines elements from the [007_timeout_failover](../007_timeout_failover/README.md) and [008_script_submitter](../008_script_submitter/README.md) workflows. Similar to the 008_script_submitter workflow, it submits a script to the "main" resource. In line with the 007_timeout_failover workflow, it also triggers the submission of a second script to the "burst" resource in case of job failure or timeout. Please refer to the README of each of these workflows for more detailed information. Below are sample scripts for submission to the controller, SLURM, and PBS, respectively:

```
#!/bin/bash
hostname
```

```
#!/bin/bash
#SBATCH --job-name=my_job_name
#SBATCH --ntasks=1
#SBATCH --time=00:10:00
hostname
```


```
#!/bin/bash
#PBS -N my_job_name
#PBS -l nodes=1:ppn=1
#PBS -l walltime=00:10:00
#PBS -q B30
hostname
```
