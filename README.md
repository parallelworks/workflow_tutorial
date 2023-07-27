# Simple Bash Demo
In [this](https://github.com/parallelworks/simple_bash_demo/tree/main) repository, you will find a comprehensive series of progressively complex tutorials on workflow building. These tutorials are specifically designed to guide you through the diverse features and options available for creating workflows on the Parallel Works platform.

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

## 5. Resource Input Wrapper
The code in this workflow is a wrapper to run before any other workflow in order to process and organize the resource information. The wrapper performs the following actions:
1. Creates a directory for each resource under the job directory.
2. Completes and validates the following resource information: public ip, internal ip, remote user, working directory, job directory and resource type. Note that this information may be missing or incorrect if the workflow was launched while the resource is starting. 
3. Creates `input.json` and `inputs.sh` files for each resource under the resource's directory. Note that this is helpful to create code that runs on each of the resources without having to parse the workflow arguments every time. 
4. Creates a batch header with the PBS or SLURM directives under the resource's directory. Note that this header can be used as the header of any script that the workflow submits to the resource. 
5. Finds a given number of available ports

### Workflow XML
The wrapper only works if the resources are defined using a specific format in the workflow.xml file.  A sample `workflow.xml` file is provided in this repository. The format has the following rules:
1. Every resource is defined in a separate section.
2. The section name is `pwrl_<resource label>`, where the prefix `pwrl_` (PW resource label) is used to indicate that the section corresponds to a resource definition section. 
3. Every section may contain the following special parameters: `jobschedulertype`, `scheduler_directives`, `_sch_ parameters` and `nports`.
4. **jobschedulertype**: Select SLURM, PBS or CONTROLLER if the workflow uses this resource to run jobs on a SLURM partition, a PBS queue or the controller node, respectively.
5. **scheduler_directives**: Use to type SLURM or PBS scheduler directives for the resource. Use the semicolon character `;` to separate parameters and do not include the `#SLURM` or `#PBS` keywords. For example, `--mem=1000;--gpus-per-node=1` or `-l mem=1000;-l nodes=1:ppn=4`.
6. **\_sch\_ parameters**: These parameters are used to directly expose SLURM and PBS scheduler directives on the input form in a way that does not require the end user to know the directives or type them using the `scheduler_directives` parameter. A special format must be used to name these parameters. The parameter name is directly converted to the corresponding scheduler directive. Therefore, new directives can be added to the XML without having to modify the workflow code. 
7. **nports**: Number of available ports to find for this resource. These ports are added to the inputs.json and inputs.sh files.

## 7. Timeout Failover
The workflow performs the following tasks:

1. Creates a job script with the specified scheduler directives for the "Main Host" resource, supporting both PBS queues and SLURM partitions.
2. Submits the job with the specified command to the "Main Host" resource.
3. Waits for the job to finish within the specified maximum time on the "Main Host" resource.
4. Exits successfully if the job finishes before the specified time.
5. If the job does not finish within the specified time, kills the job on the "Main Host".
6. Creates a job script with the specified scheduler directives for the "Burst Host" resource, supporting both PBS queues and SLURM partitions.
7. Resubmits the job to the "Burst Host".
8. Waits for the job to finish within the specified maximum time on the "Burst Host" resource.
9. Exits successfully if the job finishes before the specified time.
10. If the job does not finish within the specified time on the "Burst Host", kills the job and fails.

This workflow accommodates running the job on both PBS queues and SLURM partitions, providing flexibility for different resource configurations.

## 8. Job Submitter
The workflow is designed to seamlessly submit a specified script to a user-selected PBS or SLURM cluster resource. Usesrs have the option to enable job tracking, allowing the PW job to wait for the cluster job to complete while continuously monitoring its status. If needed, the cluster job can be canceled directly from the PW job interface.

## 9. Job Submitter
This workflow showcases transferring files between the user container and the controller and compute nodes of a cluster using rsync. Depending on the files origin and destion and which machine runs the rsync command following scenarios are covered:

1. rsync runs in the **user container** (usercontainer-runs-rsync.sh)

    1.1 Directory is transferred from the user container to the controller node

    1.2 Directory is transferred from the controller node to the user container

2. rsync runs in the **controller node** (controller-runs-rsync.sh)

    2.1 Directory is transferred from the user container to the controller node

    2.2 Directory is transferred from the controller node to the user container

3. rsync runs in the **compute node** (compute-runs-rsync.sh)

    3.1 Directory is transferred from the user container to the compute node

    3.2 Directory is transferred from the compute node to the user container
