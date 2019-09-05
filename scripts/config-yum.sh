echo "add yum repo"
rm -f /etc/yum.repos.d/CentOS-Base.repo
curl http://mirrors.163.com/.help/CentOS7-Base-163.repo -o /etc/yum.repos.d/CentOS-Base.repo
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache
yum install -y wget
echo "yum upgrade"
yum upgrade -y
yum install -y yum-utils device-mapper-persistent-data lvm2
sync