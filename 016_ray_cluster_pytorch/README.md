# Ray Cluster on Kubernetes with GPUs
This workflow deploys a Ray Cluster on a Kubernetes cluster using the ACTIVATE platform and runs a sample GPU-enabled PyTorch job.

## Overview
- ✅ **Based on the Ray's official example:** [KubeRay GPU training](https://docs.ray.io/en/latest/cluster/kubernetes/examples/gpu-training-example.html#kuberay-gpu-training-example).
- 📄 The Ray Cluster configuration is defined in the ray-cluster.gpu.yaml file included in this workflow's directory.
- 🖥️ The workflow automatically creates a port-forwarding session for the Ray Dashboard
- 🔁 **Supports multiple job submissions:** Users can submit additional jobs while the workflow is running by using the workflow interface and specifying the port of the dashboard session.

🧼 **Cleanup included:** When the workflow is terminated, it automatically uninstalls the KubeRay operator and the Ray Cluster, restoring the cluster to its original state.

## Usage
1. **Deploy the Cluster:** Set `deploy_ray_cluster` to `true` to deploy a fresh Ray Cluster. 
2. **Submit Jobs:** While the workflow is running, additional jobs can be submitted. If reusing an existing cluster, set `deploy_ray_cluster` to `false` and provide the existing dashboard port.
3. **Train with PyTorch on GPU:** The workflow includes a sample training script, `train_gpu_pytorch.py`, which runs as a Ray job using GPU resources.
3. **Workflow Termination:** When the workflow is canceled or completed port forwarding is stopped, the Ray Cluster is deleted, the KubeRay operator is uninstalled. This ensures the Kubernetes cluster remains clean and free of leftover resources.