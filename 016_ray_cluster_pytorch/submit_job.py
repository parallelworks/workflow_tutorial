from ray.job_submission import JobSubmissionClient

# Connect to the Ray cluster and submit the job
client = JobSubmissionClient("http://127.0.0.1:8265")
job_id = client.submit_job(
    entrypoint="python train_gpu_pytorch.py",
    runtime_env={"working_dir": "."}  # Directory containing train.py
)
print(f"{job_id}")
#print(f"View logs with: ray job logs {job_id} --address http://127.0.0.1:8265 --follow")