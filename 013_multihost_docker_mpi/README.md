## MPI Docker Hello World
This workflow demonstrates executing a multinode MPI job within a SLURM cluster using Docker. It comprises two scripts: 
- `main.sh` submits hello-world-mpi-docker.sh to the chosen SLURM resource through SSH. 
- `hello-world-mpi-docker.sh` is an independent script illustrating the utilization of multinode MPI with Docker in a SLURM environment, employing Docker Swarm to establish a container cluster.

Users can specify a Docker repository containing OpenMPI and configure the number of nodes and partition scheduler directives for job submission. Notably, all available cores are utilized for the MPI hello world, thus `--exclusive` scheduler directive is hardcoded in `hello-world-mpi-docker.sh`. Additionally, `--ntasks-per-node` is set to 1 in `hello-world-mpi-docker.sh`, reflecting a single Docker container per node.