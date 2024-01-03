## Script Submitter
The workflow is designed to seamlessly submit a specified script to a user-selected PBS or SLURM cluster resource. Users have the option to enable job tracking, allowing the PW job to wait for the cluster job to complete while continuously monitoring its status. If needed, the cluster job can be canceled directly from the PW job interface.

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
