output=$(consul acl token read -id $2 -http-addr=$1 -token=$3)
secretId=$(echo "$output" | sed -n '2,2p' | cut -d ":" -f 2 | tr -d '[:space:]')
echo {\"secretId\":\"$secretId\"}