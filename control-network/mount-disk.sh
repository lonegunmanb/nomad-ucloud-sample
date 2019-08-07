set -e
mkfs.ext4 /dev/vdb
mkdir /${project_root_dir}
mount /dev/vdb /${project_root_dir}
echo 'mount /dev/vdb /${project_root_dir}'>>/etc/rc.d/rc.local