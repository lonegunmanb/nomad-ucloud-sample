echo "add yum repo"
yum install -y wget
rm -f /etc/yum.repos.d/CentOS-Base.repo
wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.163.com/.help/CentOS7-Base-163.repo
yum-config-manager --add-repo https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum makecache
echo "yum upgrade"
yum upgrade -y
yum install -y yum-utils device-mapper-persistent-data lvm2
sync