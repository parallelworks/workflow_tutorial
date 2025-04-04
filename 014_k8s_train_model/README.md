# Workflow Description
This workflow automates a machine learning training job on a Kubernetes cluster using kubectl. It trains a CNN on the MNIST dataset with PyTorch and GPU support. If any step fails, the workflow sends a notification..


Key steps include:

### Authentication
Authenticates kubectl with the specified cluster (default: minikubegpu) using the **pw client**.

### Kubernetes Deployment:
- Generates a unique job_id.
- Creates a ConfigMap with the training script.
- Sets up a PVC (default: 1Gi) for model storage.
- Deploys a training job using a PyTorch GPU container.
- Monitors job progress and prints logs.
- Deploys a temporary pod to copy the model file locally
- Cleans up resources post-execution.

### Training Script:
- Defines a CNN for MNIST classification.
- Trains on GPU if available.
- Saves the model to the PVC.


It provides a scalable, automated solution for GPU-accelerated training in Kubernetes.

