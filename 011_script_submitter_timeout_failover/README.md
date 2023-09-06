## Script Submitter with Timeout and Failover
This workflow is a combination of the [007_timeout_failover](../007_timeout_failover/README.md) and [008_script_submitter](../008_script_submitter/README.md) workflows. In this case, the workflow submits a script to the "main" resource (see [008_script_submitter](../008_script_submitter/README.md) workflow). If the job fails or times out it submits a second script to the "burst" resource (see [007_timeout_failover](../007_timeout_failover/README.md) workflow). Here are some sample scripts to submit to the controller, SLURM and PBS, respectively:

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
