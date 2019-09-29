echo "install docker-ce"
if [[ ! -z "${DOCKER_RPM}" ]]; then
  wget -nv -O docker-ce.rpm ${DOCKER_RPM}
  yum install -y docker-ce.rpm
  rm -f docker-ce.rpm
else
  yum install -y docker-ce
fi

if [[ ! -z "${DOCKER_CLI_RPM}" ]]; then
  wget -nv -O docker-cli.rpm ${DOCKER_CLI_RPM}
  yum install -y docker-cli.rpm
  rm -f docker-cli.rpm
else
  yum install -y docker-ce-cli
fi

systemctl enable docker
sync
