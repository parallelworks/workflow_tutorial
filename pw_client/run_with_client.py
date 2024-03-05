import requests, os, json
from time import sleep
from datetime import datetime

def printd(*args):
    print(datetime.now(), *args)


# LOAD PLATFORM HOST AND API KEY FROM ENVIRONMENT
PW_PLATFORM_HOST: str = os.environ['PW_PLATFORM_HOST']
PW_KEY: str = os.environ['PW_API_KEY']

# DEFINE JOB
workflow_name: str = 'simple_bash_demo'

# JOB INPUTS
# This is the dictionary corresponding to the JSON file /pw/jobs/<workflow-name>/<job-number>/inputs.json
# You can also view the contents of this in https://cloud.parallel.works/workflows/<workflow-name>/json
inputs = {
    "command": "sleep 10",
    "resource_1": {
        "type": "computeResource",
        "id": "647e3185ff9be06dd443ab98"
    },
    "startCmd": "001_single_resource_command/main.sh"
}

# SUBMIT POST REQUEST
body = {
    "variables": inputs
}
workflow_endpoint = f"https://{PW_PLATFORM_HOST}/api/v2/workflows/{workflow_name}/start?key={PW_KEY}"
response = requests.post(workflow_endpoint, json=body)
response_dict = response.json()

if response.status_code == 200:
    print("POST request successful!")
else:
    print(f"POST request failed with status code: {response.status_code}")

print(json.dumps(response_dict, indent = 4))

# (OPTIONAL) WAIT FOR JOB
job_number = response_dict['job']['number']
job_endpoint = f'https://{PW_PLATFORM_HOST}/api/v2/workflows/{workflow_name}/getJob?key={PW_KEY}&jobNumber={job_number}'
while True:
    response = requests.get(job_endpoint)
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
