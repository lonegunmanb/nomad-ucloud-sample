while true; do
  consul kv put ipv6/${server_id} ${ipv6}
  if [ $? -eq 0 ]; then
      break
  fi
  sleep 10
done