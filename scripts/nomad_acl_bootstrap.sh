output=$(nomad acl bootstrap -address=$1)
accessorId=$(echo "$output" | sed -n '1,1p' | cut -d "=" -f 2 | tr -d '[:space:]')
secretId=$(echo "$output" | sed -n '2,2p' | cut -d "=" -f 2 | tr -d '[:space:]')
echo {\"accessorId\":\"$accessorId\"\,\\n\"secretId\":\"$secretId\"}