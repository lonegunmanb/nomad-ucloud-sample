FROM alpine

ENV VERSION=0.11.14

RUN apk add wget unzip ca-certificates \
 && wget -O /tmp/terraform.zip https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip \
 && unzip -d /usr/bin /tmp/terraform.zip \
 && rm -rf /tmp/* \
 && mkdir /plugin \
 && echo plugin_cache_dir = \"/plugin\" >> ~/.terraformrc