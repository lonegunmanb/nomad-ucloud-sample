if [[ -z "${TERRAFORM}" ]]; then
  terraform="terraform"
else
  terraform="${TERRAFORM}"
fi
while true; do
  $terraform apply --auto-approve -input=false
  if [ $? -eq 0 ]; then
      break
  fi
done