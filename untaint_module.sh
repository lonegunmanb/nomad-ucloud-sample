module=$1

for resource in `terraform show | grep module.${module} | tr -d ":"  | tr -d "#"`; do
	terraform untaint ${resource}
done
