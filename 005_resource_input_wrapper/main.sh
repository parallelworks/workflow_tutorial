#!/bin/bash
source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate
python3 /swift-pw-bin/utils/input_form_resource_wrapper.py 

resource_labels=$(cat workflow.xml | grep section | grep -E 'pwrl_' |  awk -F "'" '{print $2}' | sed "s|pwrl_||g" )
echo "RESOURCE LABELS: ${resource_labels}"
for rl in ${resource_labels}; do
    echo; echo "Resource Label: ${rl}"
    source resources/${rl}/inputs.sh
    cat resources/${rl}/inputs.sh
    # Write code to run on each resource here
    ssh  -o StrictHostKeyChecking=no ${resource_publicIp} hostname

done