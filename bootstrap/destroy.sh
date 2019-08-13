cd /project/${project_dir}
while true; do
  if [ ! -f "destroyed" ]; then
    terraform destroy -force -var-file=backend.tfvars
    if [ $? -eq 0 ]; then
        break
    fi
  else
    break
  fi
done
touch destroyed

cd network
while true; do
  if [ ! -f "destroyed" ]; then
    terraform destroy -force -var-file=backend.tfvars
    if [ $? -eq 0 ]; then
        break
    fi
  else
    break
  fi
done
touch destroyed

cd ../control-network
while true; do
  terraform destroy -force
  if [ $? -eq 0 ]; then
        break
  fi
done