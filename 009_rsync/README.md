## Rsync
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
