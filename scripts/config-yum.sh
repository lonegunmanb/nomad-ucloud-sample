echo "add yum repo"
sed -i 's/enabled=1/enabled=0/g' /etc/yum/pluginconf.d/fastestmirror.conf
rm -f /etc/yum.repos.d/CentOS-Base.repo
curl ${YUM_BASE} -o /etc/yum.repos.d/CentOS-Base.repo

if [[ ! -z "${YUM_DOCKER}" ]]; then
  yum-config-manager --add-repo ${YUM_DOCKER}
fi

yum makecache
yum install -y wget
echo "yum upgrade"
yum upgrade -y
yum install -y yum-utils device-mapper-persistent-data lvm2
sync