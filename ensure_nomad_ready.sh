while true; do
  echo "ensure nomad ready"
  nomad operator raft list-peers
  if [ $? -eq 0 ]; then
      break
  fi
done