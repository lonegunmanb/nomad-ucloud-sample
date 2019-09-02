FROM alpine

ARG VERSION=0.12.5

RUN echo "https://mirrors.cloud.tencent.com/alpine/latest-stable/main/" > /etc/apk/repositories \
 && apk add wget unzip ca-certificates \
 && wget -O /tmp/terraform.zip http://hashicorpfile.cn-bj.ufileos.com/terraform_${VERSION}_linux_amd64.zip \
 && unzip -d /usr/bin /tmp/terraform.zip \
 && rm -rf /tmp/* \
 && mkdir /plugin \
 && echo plugin_cache_dir = \"/plugin\" >> ~/.terraformrc