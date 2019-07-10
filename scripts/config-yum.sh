echo "add yum repo"
yum install -y yum-utils device-mapper-persistent-data lvm2
yum-config-manager --add-repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum-config-manager --add-repo https://mirrors.cloud.tencent.com/docker-ce/linux/centos/docker-ce.repo
yum makecache
echo "yum upgrade"
yum upgrade -y
sync