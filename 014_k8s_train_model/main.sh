#!/bin/bash
cd $(dirname $0)
set -xe

# Create a job identifier
job_number=${RANDOM}

configmap_name="train-script-${job_number}"
pvc_name="model-storage-${job_number}"
train_job_name="mnist-train-${job_number}"

pvc_storage="1Gi"

######################################
# INITIALIZE TRAINING CLEANUP SCRIPT #
######################################
echo '#!/bin/bash' > training_cleanup.sh
chmod +x training_cleanup.sh

# Function to perform cleanup tasks
training_cleanup() {
  echo; echo "Running cleanup"
  kubectl delete configmap ${configmap_name}
}

# Trap signals for graceful shutdown
trap training_cleanup EXIT INT TERM

#####################################
# ADD TRAINING SCRIPT TO CONFIG MAP #
#####################################
echo "kubectl delete configmap ${configmap_name}" >> training_cleanup.sh
kubectl create configmap ${configmap_name} --from-file=train-script.py

########################################
# CREATE PERSISTENT VOLUME CLAIM (PVC) #
########################################
# Create pvc.yaml configuration
cat > pvc.yaml <<HERE
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ${pvc_name}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: ${pvc_storage}
HERE

# Apply pvc.yaml configuration
echo "kubectl delete -f pvc.yaml" >> training_cleanup.sh
kubectl apply -f pvc.yaml


#######################
# CREATE TRAINING JOB #
#######################
# Create train-job.yaml configuration
cat > train-job.yaml <<HERE
apiVersion: batch/v1
kind: Job
metadata:
  name: ${train_job_name}
spec:
  template:
    spec:
      containers:
      - name: trainer
        image: pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
        command: ["python", "/scripts/train-script.py"]
        resources:
          limits:
            nvidia.com/gpu: 1
        volumeMounts:
        - mountPath: "/mnt/model"
          name: ${pvc_name}
        - mountPath: "/scripts"
          name: script-volume
      volumes:
      - name:  ${pvc_name}
        persistentVolumeClaim:
          claimName:  ${pvc_name}
      - name: script-volume
        configMap:
          name: ${configmap_name}
      restartPolicy: Never
  backoffLimit: 2
HERE

# Apply train-job.yaml configuration
echo "kubectl delete -f train-job.yaml " >> training_cleanup.sh
kubectl apply -f train-job.yaml 


###########################################
# WAIT FOR JOB TO COMPLETE AND PRINT LOGS #
###########################################
# Wait for the pod to start (i.e., exist and not be in ContainerCreating state)
echo "Waiting for pod to start..."
until kubectl get pod -l job-name=${train_job_name} -o jsonpath="{.items[0].status.phase}" >/dev/null 2>&1 && [ "$(kubectl get pod -l job-name=${train_job_name} -o jsonpath='{.items[0].status.phase}')" != "Pending" ] || [ "$(kubectl get pod -l job-name=${train_job_name} -o jsonpath='{.items[0].status.phase}')" = "Running" ]; do
  echo "Pod is not yet started. Waiting..."
  sleep 2
done


# Wait for the job to finish (either Complete or Failed)
echo "Waiting for job ${train_job_name} to finish..."
kubectl wait --for=condition=Complete job/${train_job_name} --timeout=600s || \
kubectl wait --for=condition=Failed job/${train_job_name} --timeout=600s

# Get the pod name associated with the job
pod_name=$(kubectl get pod -l job-name=${train_job_name} -o jsonpath="{.items[0].metadata.name}")

# Check if pod_name is empty (i.e., no pod found)
if [ -z "$pod_name" ]; then
  echo "Error: No pod found for job ${train_job_name}"
  exit 1
fi

# Print the pod name
echo "Pod name: ${pod_name}"
echo "kubectl delete pod ${pod_name} --force --grace-period=0" >> training_cleanup.sh

# Print the logs of the pod
kubectl logs ${pod_name}


######################
# COPY TRAINED MODEL #
######################
# Start a pod using the same container image for file transfer
cat > transfer-pod.yaml <<HERE
apiVersion: v1
kind: Pod
metadata:
  name: model-transfer-${job_number}
spec:
  containers:
  - name: transfer
    image: pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime
    command: ["sleep", "3600"]
    volumeMounts:
    - mountPath: "/mnt/model"
      name: ${pvc_name}
  volumes:
  - name: ${pvc_name}
    persistentVolumeClaim:
      claimName: ${pvc_name}
  restartPolicy: Never
HERE

# Apply the transfer pod configuration
echo "kubectl delete -f transfer-pod.yaml" >> training_cleanup.sh
kubectl apply -f transfer-pod.yaml

# Wait for the transfer pod to be running
echo "Waiting for transfer pod to start..."
kubectl wait --for=condition=Ready pod/model-transfer-${job_number} --timeout=300s

# Copy the model file from the PVC to the local machine
kubectl cp model-transfer-${job_number}:/mnt/model/mnist_cnn.pt ./mnist_cnn.pt