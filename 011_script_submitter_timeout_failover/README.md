## Script Submitter with Timeout and Failover

Here are some sample scripts to submit to the controller, SLURM and PBS, respectively:

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