#!/bin/bash
# Load  workflow parameter names and values from the XML as environment variables
# In this case: command, resource_1_username, resource_1_publicIp
source inputs.sh

echo; echo "Running command [${command}] on resource 1"
if [[ ${resource_1_name} == "user_workspace" ]]; then
    ${command}
else
    ssh -o StrictHostKeyChecking=no ${resource_1_username}@${resource_1_publicIp} "${command}"
fi
