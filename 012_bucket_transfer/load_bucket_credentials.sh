
echo "LOADING BUCKET NAME AND SHORT-TERM CREDENTIALS"
# Note that this script has access to all the variables in inputs.sh (create at runtime form the workflow.xml)
# Load bucket name and credentials by calling the bucket_token_generator.py script
# This script needs to be in your user container because it needs access to the PW_API_KEY environment variable
# If this script runs in the controller node the jump host in the ssh command is optional 

# Get SSH options to ssh back to the user container
# In On-Prem clusters the SSH config is not included
# in ~/.ssh/config. 
if [ -e "${HOME}/pw/.pw/config" ]; then
    # Check if the SSH config for the compute node exists
    # Assumes the work directory of the cluster is ${HOME}
    SSH_USERCONTAINER_OPTIONS="-F ${HOME}/pw/.pw/config"
else
    SSH_USERCONTAINER_OPTIONS="-J ${resource_privateIp}"
fi


eval $(ssh ${SSH_USERCONTAINER_OPTIONS} usercontainer ${token_generator_path} --bucket_id ${bucket_id} --token_format text)
