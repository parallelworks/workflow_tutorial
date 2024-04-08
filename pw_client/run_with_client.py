import requests, os, json
from time import sleep
from datetime import datetime
from base64 import b64encode

def encode_string_to_base64(text):
    # Convert the string to bytes
    text_bytes = text.encode('utf-8')
    # Encode the bytes to base64
    encoded_bytes = b64encode(text_bytes)
    # Convert the encoded bytes back to a string
    encoded_string = encoded_bytes.decode('utf-8')
    return encoded_string

def printd(*args):
    print(datetime.now(), *args)


# LOAD PLATFORM HOST AND API KEY FROM ENVIRONMENT
PW_PLATFORM_HOST: str = os.environ['PW_PLATFORM_HOST']
HEADERS = {"Authorization": "Basic {}".format(encode_string_to_base64(os.environ['PW_API_KEY']))}

# DEFINE JOB
workflow_name: str = 'simple_bash_demo'

# JOB INPUTS
# You can view the contents of this in https://cloud.parallel.works/workflows/<workflow-name>/json
inputs = {
  "command": "hostname",
  "resource_1": {
    "type": "computeResource",
    "id": "6419f5bd7d72b40e5b9a2af7"
  },
  "startCmd": "001_single_resource_command/main.sh"
}

# SUBMIT POST REQUEST TO CREATE NEW WORKFLOW JOB
body = {
    "variables": inputs
}
workflow_endpoint = f"https://{PW_PLATFORM_HOST}/api/v2/workflows/{workflow_name}/start"
response = requests.post(workflow_endpoint, json=body, headers = HEADERS)
response_dict = response.json()

if response.status_code == 200:
    print("POST request successful!")
else:
    print(f"POST request failed with status code: {response.status_code}")

print(json.dumps(response_dict, indent = 4))

# (OPTIONAL) WAIT FOR JOB
job_number = response_dict['job']['number']
job_endpoint = f'https://{PW_PLATFORM_HOST}/api/v2/workflows/{workflow_name}/getJob'
job_endpoint_params = {
    "jobNumber": job_number
}

while True:
    response = requests.get(job_endpoint, headers = HEADERS, params = job_endpoint_params)
    job_status = response.json()['status']
    printd(f'Workflow <{workflow_name}>, job <{job_number}>, status <{job_status}>')
    if job_status == 'completed' or job_status == 'canceled':
        break
    elif job_status == 'error':
        raise(Exception(f'Job <{job_number}> failed!'))
    elif  job_status == 'running':
        sleep(5)
    else:
        raise(Exception(f'Job <{job_number}> has unkown status <{job_status}>!'))
