echo untaint everything
for resource in `terraform show | grep '#' | grep -v 'rendered' | grep -v  'template' | tr -d ":"  | tr -d "#"`; do
	terraform untaint ${resource} &>/dev/null
done
