# StableDiffusion Text-to-Image Model on Kubernetes
This workflow deploys a RayService on a Kubernetes cluster using the ACTIVATE platform. It's designed to run Stable Diffusion as a Ray Serve app via a KubeRay-managed Ray cluster.

## Overview
- ✅ **Based on the RayService example** available [here](https://docs.ray.io/en/latest/cluster/kubernetes/examples/stable-diffusion-rayservice.html#kuberay-stable-diffusion-rayservice-example).
- 🖼️ Generated images are saved in the job's directory.
- 📄 The RayService configuration is defined in the ray-service.stable-diffusion.yaml file included in this workflow's directory.

- 🔁 **Supports interactive prompts:** Users can submit additional prompts while the workflow is running by using the workflow interface and specifying the correct service port.

🧼 **Cleanup included:** When the workflow is terminated, it automatically uninstalls the KubeRay operator and the RayService, restoring the cluster to its original state.

## Usage
1. **Deploy the Service:** Set deploy_ray_service to true to deploy a fresh RayService instance. 
2. **Submit Prompts:** While the workflow is running, additional prompts can be submitted. If not deploying a new service, set `deploy_ray_service` to `false` and provide the existing service's port.
3. **Workflow Termination** When the workflow is canceled or completed: port forwarding is stopped, the RayService is deleted, the KubeRay operator is uninstalled. This ensures the Kubernetes cluster remains clean and free of leftover resources.