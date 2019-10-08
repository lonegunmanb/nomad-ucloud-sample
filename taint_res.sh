res=$1

for resource in `terraform show | grep ${res} | grep '#' | tr -d ":"  | tr -d "#"`; do
	terraform taint ${resource}
done
