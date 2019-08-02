mkfs.ext4 /dev/vdb
mount /dev/vdb /${project_root_dir}
echo 'mount /dev/vdb /${project_root_dir}'>>/etc/rc.d/rc.local