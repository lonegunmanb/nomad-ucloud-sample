terraform=$TERRAFORM
if [$terraform -eq ""]
  terraform="terraform"
fi
while true; do
  $terraform apply --auto-approve -input=false
  if [ $? -eq 0 ]; then
      break
  fi
done