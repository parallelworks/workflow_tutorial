## MPI Hello World
This workflow automates the compilation and execution of a simple hello world MPI job on a remote cluster. It does the following steps:
1. Loads workflow parameters
2. Creates compilation and run scripts
3. Transfers requires files
4. Compiles on the cluster in the scheduler of the cluster
5. Submits the job directly to the scheduler, to the SLURM partition or to the PBS queue
6. Optionally waits for job completion.
