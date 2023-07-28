## Cancel Job
This workflow performs the following tasks:

1. Generates a SLURM script based on the command entered in the input form.
2. Transfers the generated script to the designated directory on the chosen SLURM resource.
3. Submits the associated job to the queue for execution.
4. Generates a kill script to terminate the SLURM job if the workflow job is cancelled.
5. Periodically checks the status of the job.
6. Concludes successfully when the SLURM job is finished and fails if the SLURM job encounters an error