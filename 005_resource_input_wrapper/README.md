## Resource Input Wrapper
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
