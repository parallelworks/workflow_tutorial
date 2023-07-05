# Simple Bash Demo
In this repository, you will find a comprehensive series of progressively complex tutorials on workflow building. These tutorials are specifically designed to guide you through the diverse features and options available for creating workflows on the Parallel Works platform.

## 1. Single Resource Command
This workflow allows you to run a specific command on the controller or login node of a selected resource using SSH. The command can include srun, sbatch, or qsub commands for executing jobs on SLURM partitions or PBS queues.

The workflow definition form consists of two parameters. The "command" parameter is a text field where you define the command to be executed, and the "resource" parameter allows you to choose any currently running resource in your account.

When a job is submitted, the workflow files are copied to the job directory `/pw/jobs/<workflow-name>/<job-number>/`, and the command specified in the workflow XML is launched from there. The names of the workflow parameters are defined in the XML and the values are selected in the input form and written to the `inputs.sh` and `inputs.json` files within the job directory. Please note that these files contain the same data in different formats. The workflow loads the parameter values by sourcing the `inputs.sh` file.

## 2. Double Resource Command
This workflow runs the command on two resources

## 3. Cancel Job
This workflow performs the following tasks:

1. Generates a SLURM script based on the command entered in the input form.
2. Transfers the generated script to the designated directory on the chosen SLURM resource.
3. Submits the associated job to the queue for execution.
4. Generates a kill script to terminate the SLURM job if the workflow job is cancelled.
5. Periodically checks the status of the job.
6. Concludes successfully when the SLURM job is finished and fails if the SLURM job encounters an error
 
## 4. Sample Complex XML
This workflow offers a comprehensive XML file that serves as an illustrative example showcasing the various parameter types that can be utilized to define an input form. Upon execution, the workflow prints the `inputs.sh` and `inputs.json`, which contain the parameter names, defined in the XML file, and their corresponding parameter values, selected in the input form.
