set -e
rm -f /etc/ssh/ssh_host_*
echo -e 'y\n' | ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_dsa_key
echo -e 'y\n' | ssh-keygen -q -N "" -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key
echo -e 'y\n' | ssh-keygen -q -N "" -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key