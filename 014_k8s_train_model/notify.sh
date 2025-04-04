#!/bin/bash
# Load job_number and workflow_name
source job.info
step=$1
step_number=$2

# Needed for now to get the PW_PLATFORM_HOST and PW_API_KEY
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh

job_number_without_zeroes=$(echo "${job_number}" | sed 's/^0*//')

url="/workflows/${workflow_name}/runs/${job_number_without_zeroes}"
title="Job ${job_number} in workflow ${workflow_name} has failed at step ${step}"
message="$(cat logs/k8s_deployment/step_${step_number}/logs.out  | sed 's|^+ ||')"
# Escape the message content for JSON using jq
escaped_message=$(echo "$message" |  jq -R -s 'split("\n") | join("\\n")')
escaped_message=$(echo "$message" | jq -R -s 'split("\n") | map(select(. != "") | "- " + .) | join("\n")')


# Send notification if status is Running
echo "Posting notification"
curl -s \
    -X POST -H "Content-Type: application/json" \
    -d "{\"title\": \"${title}\", \"message\": ${escaped_message}, \"href\": \"${url}\", \"type\": \"workflow\", \"subtype\": \"readyInteractive\"}" \
    https://${PW_PLATFORM_HOST}/api/v2/notifications \
    -H "Authorization: Basic $(echo ${PW_API_KEY}|base64)"

exit 0