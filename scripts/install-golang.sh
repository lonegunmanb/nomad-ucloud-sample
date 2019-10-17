wget -nv -O /tmp/go.tar.gz ${FILE_SERVER}/go${GOLANG_VERSION}.linux-amd64.tar.gz
tar -xzf /tmp/go.tar.gz
rm -f /tmp/go.tar.gz
mv go /usr/local
mkdir /go
