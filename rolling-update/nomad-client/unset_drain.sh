while true; do
  echo "stop drain node"
  nomad node drain -self -disable
  if [ $? -eq 0 ]; then
      break
  else
    sleep 5
  fi
done
