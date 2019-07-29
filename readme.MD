## 警告
本项目仅作为概念验证，所有服务器都可从公网访问，并且没有配置ACL，请勿直接用作生产环境

## 前置准备

本脚本利用了packer在ucloud上构建了三个主机镜像，分别是consul-server/nomad-server/nomad-client，然后利用terraform在UCloud上编排出一个Nomad集群供测试把玩用。

欲运行该脚本，需要准备的工具有：
* golang
* hashicorp packer with ucloud provider
* hashicorp terraform

## 安装golang
* [golang下载地址](https://golang.org/dl/)
* [golang配置教程](https://golang.org/doc/install)

注意，本教程假设您已正确配置了GOROOT以及GOPATH环境变量，如果您不理解这两个环境变量，请仔细阅读golang配置教程

## 安装Hashicorp packer with ucloud provider

命令行中执行
```bash
go get -u github.com/hashicorp/packer
```

仓库比较大，请耐心等待

go get结束后，执行以下语句：
```bash
go install github.com/hashicorp/packer
```

成功安装后执行packer -version，看到正确输出即可
```bash
$ packer -version
1.4.3
```

（注：本文写作时UCloud Packer Builder已整合进master分支，但已发布的1.4.2版本并未包含该Builder，所以在1.4.3正式版推出之前，各位老爷们只能先麻烦自己go install一下，1.4.3正式推出后直接下载使用官方二进制版本即可）

## 安装Hashicorp Terraform
本教程已改用Terraform 0.12版本，如果要使用0.11版本，请使用terraform@0.11分支（已停止继续开发），并使用0.11版本可执行文件：

[terraform 0.11](https://releases.hashicorp.com/terraform/0.11.14/)

下载对应版本后，设置好Path，执行terraform -version能够正确看到输出结果即可
```bash
$ terraform -version
Terraform v0.12.5
```

## 构建镜像
构建镜像之前，注意到consul-server.json/nomad-server.json/nomad-client.json三个packer脚本中头部都用了环境变量传递ucloud key：
```json
"ucloud_public_key": "{{env `UCLOUD_PUBKEY`}}",
"ucloud_private_key": "{{env `UCLOUD_SECRET`}}",
```

可以手动把双引号内从花括号开始的变量替换成您的ucloud key，也可以把ucloud key设置到对应的环境变量UCLOUD_PUBKEY和UCLOUD_SECRET里，ssh_password是构建镜像所用服务器的root口令，由于构建过程中服务器可以通过公网访问，所以建议设置一个强口令（构建镜像时的口令不一定要与后续构建集群时设置的一样，在这里可以是一个临时性的口令）。ucloud_project_id变量是您的UCloud项目ID，具体取值可以用登陆控制台首页后在左上角的"项目ID"

然后按照顺序执行:
```bash
packer build consul-server.json
packer build nomad-server.json
packer build nomad-client.json
```

packer完成构建后会输出镜像id，可以把三个镜像id分别填入variables.tf文件中的consul_server_image_id/nomad_server_image_id/nomad_client_image_id三个变量当中

## 填写variables.tf
* consul_server_root_password/nomad_server_root_password/nomad_client_root_password分别是三种主机的root账号口令（由于测试集群直接暴露在公网，所以口令还请设置的长且复杂一些）
* ucloud_pub_key/ucloud_secret是您的UCloud账号的api公私钥（点击控制台首页右上角头像，然后点击"API密钥"可以查看）
* region/az目前是UCloud的北京2地域的C/D/E可用区
* allow_ip目前是0.0.0.0/0，建议改成yourip/32
* project_id填写您的ucloud project id(登陆控制台首页后左上角的"项目ID")
* consul_server_type/nomad_server_type/nomad_client_type分别代表consul server/nomad server/nomad client三种服务器的机型（具体机型说明请看[这里](https://www.terraform.io/docs/providers/ucloud/r/instance.html#instance_type)）

## 填写network/variables.tf
network文件夹下的variables.tf需要单独填写，其余变量都与之前的一样，只有cluster_id，可以填写一个UUID，只要能帮助我们在生产环境区分服务器所属的集群即可

## 创建集群

由于UCloud的实现，导致测试完成后即使我们销毁了所有主机等资源，我们创建的虚拟网络也要等待几分钟才能正确删除，所以本教程选择把创建虚拟网络与创建服务器资源分成了两个独立步骤。

首先进入network文件夹，执行:
```bash
terraform init
terraform apply --auto-approve
```
成功后转到上层目录，重复执行以上两步语句(terraform init每个文件夹只需要执行一次)

执行成功后会输出consul server/nomad server/nomad client服务器的公网ip。consul server的端口是8500，nomad server的端口是4646，可以通过http访问

测试完成后，执行以下命令销毁测试环境：
```bash
terraform destroy -force
```
销毁了主机后，需要等待10分钟左右再进入network文件夹，重复执行destroy销毁网络环境

## 基于Consul Connect的Sidecar例子
job文件夹中是一个在nomad上部署一组模拟服务的例子，redis.hcl中描述了这样一组模拟服务。

group "redis" 定义了一个redis服务，它运行了uhub.service.ucloud.cn/lonegunmanb/redis:latest这个docker镜像，将宿主机的一个动态tcp端口映射到容器内的6379端口，然后在connect-proxy任务中启动了一个consul进程，对外暴露一个服务端口，代理到本机docker暴露的端口上。这时docker内的redis服务只能通过consul代理来访问。consul代理服务在consul集群中注册了名为redis的服务。

group "web" 定义了一个模拟的web服务，实际上我偷了个懒，用uhub.service.ucloud.cn/lonegunmanb/redis:5.0.5-alpine这个镜像代替了web服务，启动时会把本机consul代理任务proxy获取的宿主机端口以名为REDIS_PORT的环境变量传入容器实例。名为proxy的任务在本机启动了一个consul进程，关键是设置了upstream，表明会把请求转发到名为redis的consul服务，并且侦听localhost的一个动态端口（就是前面以环境变量方式传入容器的那个）

在nomad集群创建成功后，进入job文件夹，执行
```bash
terraform init
terraform apply --auto-approve
```
就可以在nomad集群中成功创建这样一组模拟服务(同理，job文件夹的terraform init只需执行一次)，访问NOMAD_SERVER_IP:4646，可以在job中观察到创建出来的job。登陆web任务所在的nomad client服务器，docker ps可以观察到uhub.service.ucloud.cn/lonegunmanb/redis:5.0.5-alpine这个容器的运行情况，进入容器，执行
```bash
redis-cli -h localhost -p $REDIS_PORT
```
就可以从容器访问到redis服务。我们可以stop redis的allocation，迫使它重新调度到新的client上，或是对redis任务所在的client主机进行断电操作，过一会redis任务会被重新调度到新的client主机上，这时在原先的容器内重复执行同样的操作，您会发现对容器来说redis服务的地址完全没有变化，而redis服务依然可用，服务的漂移对应用来说是透明的，服务发现的工作由consul代理了。