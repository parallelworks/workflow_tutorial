## Script Submitter with Timeout and Failover
This workflow is a combination of the 007_timeout_failover and 008_script_submitter workflow. It submits a script to the "main" resource. If the job fails or times out it submits a second script to the "burst" resource. Here are some sample scripts to submit to the controller, SLURM and PBS, respectively:

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