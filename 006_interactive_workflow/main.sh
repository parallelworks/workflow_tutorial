#!/bin/bash

source /etc/profile.d/parallelworks.sh
source /etc/profile.d/parallelworks-env.sh
source /pw/.miniconda3/etc/profile.d/conda.sh
conda activate

getOpenPort() {
    minPort=50000
    maxPort=59999

    # Loop until an odd number is found
    while true; do
        openPort=$(curl -s "https://${PARSL_CLIENT_HOST}/api/v2/usercontainer/getSingleOpenPort?minPort=${minPort}&maxPort=${maxPort}" -H "Authorization: Basic $(echo ${PW_API_KEY}|base64)")
        # Check if the number is odd
        if [[ $(($openPort % 2)) -eq 1 ]]; then
            break
        fi
    done
    # Check if openPort variable is a port
    if ! [[ ${openPort} =~ ^[0-9]+$ ]] ; then
        qty=1
        count=0
        for i in $(seq $minPort $maxPort | shuf); do
            out=$(netstat -aln | grep LISTEN | grep $i)
            if [[ "$out" == "" ]] && [[ $(($i % 2)) -eq 1 ]]; then
                    openPort=$(echo $i)
                    (( ++ count ))
            fi
            if [[ "$count" == "$qty" ]];then
                break
            fi
        done
    fi
}

# Gets an available port 
getOpenPort

if [[ "$openPort" == "" ]]; then
    echo "ERROR - cannot find open port..."
    exit 1
fi

# Create kill script:
echo "kill \$(ps -x | grep python3 | grep ${openPort} | awk '{print \$1}')" > kill.sh

# Create service.json
cp service.json.template service.json
sed -i "s|__PORT__|${openPort}|g"  service.json
sed -i "s/.*JOB_STATUS.*/    \"JOB_STATUS\": \"Running\",/" service.json

# Start server in user container
python3 -m http.server ${openPort}

