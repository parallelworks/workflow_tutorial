## MPI Hello World
This workflow automates the compilation and execution of a simple hello world MPI job on a remote cluster. It does the following steps:
1. Loads workflow parameters
2. Creates compilation and run scripts
3. Transfers requires files
4. Compiles on the cluster in the scheduler of the cluster
5. Submits the job directly to the scheduler, to the SLURM partition or to the PBS queue
6. Optionally waits for job completion.


Here are some sample directives to submit SLURM and PBS, respectively:


```
#!/bin/bash
#SBATCH --ntasks-per-node=4
#SBATCH --nodes=2
#SBATCH --job-name=mpi-hello-world
```


```
#!/bin/bash
#PBS -N my_job_name
#PBS -l nodes=1:ppn=1
#PBS -l walltime=00:10:00
#PBS -q B30