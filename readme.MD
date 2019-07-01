本脚本利用了packer在ucloud上构建了三个主机镜像，分别是consul-server/nomad-server/nomad-client

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
go get github.com/shawnmssu/packer
```

仓库比较大，请耐心等待

go get结束后，执行以下语句：
```bash
cd $GOPATH/src/github.com/shawnmssu/packer
go build .
go install github.com/shawnmssu/packer
```

成功安装后执行packer -version，看到正确输出即可
```bash
$ packer -version
1.4.2
```

## 安装Hashicorp Terraform
本教程采用terraform 0.11编写，目前最新的terraform版本为0.12，并且两者语法不兼容，所以请安装0.11版本terraform

[terraform 0.11](https://releases.hashicorp.com/terraform/0.11.14/)

下载对应版本后，设置好Path，执行terraform -version能够正确看到输出结果即可
```bash
$ terraform -version
Terraform v0.11.14
+ provider.null v2.1.2
+ provider.ucloud v1.10.1

Your version of Terraform is out of date! The latest version
is 0.12.3. You can update by downloading from www.terraform.io/downloads.html
```

## 构建镜像
构建镜像之前，注意到consul-server.json/nomad-server.json/nomad-client.json三个packer脚本中头部都用了环境变量传递ucloud key：
```json
"ucloud_public_key": "{{env `UCLOUD_PUBKEY`}}",
"ucloud_private_key": "{{env `UCLOUD_SECRET`}}",
```

可以手动把双引号内从花括号开始的变量替换成您的ucloud key，也可以把ucloud key设置到对应的环境变量UCLOUD_PUBKEY和UCLOUD_SECRET里

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