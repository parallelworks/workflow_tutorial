## Bucket Transfer
This workflow executes a specified bucket command on the chosen resource, utilizing short-term credentials acquired through the `load_bucket_credentials.sh` and `bucket_token_generator.py` scripts. Note that the code in `load_bucket_credentials.sh` runs on the remote resource, while `bucket_token_generator.py` is executed in the user container via SSH to access the `PW_API_KEY` environment variable.

The workflow creates a `run.sh` script structured as follows:
```
#!/bin/bash
-----------
SLURM / PBS directives (optional)
-----------
Inputs from inputs.sh
-----------
Load bucket name and short-term credentials
-----------
Command
```

Subsequently, it submits this script to the controller node, SLURM partition, or PBS queue of the designated resource. Optionally, it can wait for job completion and cancel it if needed.