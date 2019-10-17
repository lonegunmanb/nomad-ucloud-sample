## 构建镜像

首先使用packer在ucloud上构建了三个云主机镜像，分别是consul-server/nomad-server/nomad-client

欲运行该脚本，我们需要在执行代码的环境中准备：
* hashicorp packer (>= v1.4.4)  [how to install](https://www.packer.io/intro/getting-started/install.html)
* hashicorp terraform (>= v0.12.0) [how to install](https://learn.hashicorp.com/terraform/getting-started/install)

packer构建的[基本命令](https://www.packer.io/docs/commands/build.html)是：
```shell script
packer build xxxx.json
```

构建镜像之前，注意到consul-server.json/nomad-server.json/nomad-client.json三个packer脚本中头部都用了环境变量传递ucloud key：
```json
"ucloud_public_key": "{{env `UCLOUD_PUBKEY`}}",
"ucloud_private_key": "{{env `UCLOUD_SECRET`}}",
```

可以把ucloud key设置到对应的环境变量UCLOUD_PUBKEY和UCLOUD_SECRET里，又或者或者建议您可以传入一个独立的参数文件：
```shell script
packer build -var-file=xxx-var.json xxx.json
```
参数文件中的参数值会覆盖您在packer脚本中定义的值。如果使用参数文件，由于其中可能含有您的app key、密码等信息，请注意不要泄漏该文件文件，或是将文件错误签入源代码管理。

```json
"ssh_password": "",
```
ssh_password是构建镜像所用服务器的root口令，由于构建过程中服务器可能可以通过公网访问，所以建议设置一个强口令（构建镜像时的口令不一定要与后续构建集群时设置的一样，在这里可以是一个临时性的口令）。ucloud_project_id变量是您的UCloud项目ID，具体取值可以用登陆控制台首页后在左上角的"项目ID"

image_id代表构建镜像所使用的基础镜像，类似Dockerfile中的FROM；本文采用的是CentOS 7.x。由于部分UCloud机房的本地SSD盘仅支持CentOS 7.2及以下版本，建议您使用CentOS 7.2。

想要查询对应机房的CentOS基础镜像ID，最方便的方法是通过[UCloud CLI工具](https://github.com/ucloud/ucloud-cli)。您可以安装配置好UCloud CLI后，执行:
```shell script
ucloud image list | grep "CentOS 7."
```
注意，同版本镜像在不同机房的镜像ID不同，请注意查询时UCloud CLI配置的区域要与您Packer脚本中的region保持一致。

推荐编写类似这样的参数文件consul-server-vars.json：
```json
{
  "ucloud_public_key": "xxxxxxxxxxxxxxxx",
  "ucloud_private_key": "yyyyyyyyyyyyyy",
  "ssh_user": "root",
  "ssh_password": "passwordpassword",
  "ucloud_project_id": "org-projectid",
  "image_id": "uimage-yyyyyy",
  "consul_version": "1.6.1",
  "region": "cn-sh2",
  "az": "cn-sh2-03",
  "yum_base": "https://mirrors.aliyun.com/repo/Centos-7.repo",
  "use_ssh_private_ip": "false"
}
```

如上所述，配置好三个参数文件后，按照顺序执行:
```bash
packer build -var-file=consul-server-vars.json consul-server.json
packer build -var-file=nomad-server-vars.json nomad-server.json
packer build -var-file=nomad-client-vars.json nomad-client.json
```

三个脚本也可以同时并行执行，彼此不会互相影响。packer完成构建后会输出镜像id，让我们先妥善保存三个id，在后续的工作中我们将要使用它们。

## Packer脚本详解

总体来说，consul-server/nomad-client/nomad-server的Packer脚本所做的事是相似的，基本都是：
1. 配置yum源
2. 安装、配置consul/nomad的systemd服务
3. 写入配置文件模版

其中，nomad-client还需要：
1. 安装docker
2. 配置Terraform插件缓存

本文撰写时已将所需要的所有外部依赖文件提前上传至ufile中，packer脚本中的file_server变量给定了默认的基础访问地址：http://hashicorpfile.cn-bj.ufileos.com，如果您需要修改基础访问地址，可以在参数文件中传递。

### 配置yum源
由于国内直接访问默认yum源速度非常感人，所以一般我们第一步需要配置使用国内yum源。packer中的yum_base变量就是用来指定我们希望使用的国内yum源。请注意，如果是在不可访问公网的环境构建时，该变量留空，就会使用默认yum源。
yum_docker变量是用来配置含有docker安装包的yum源的，同样，在不可访问公网的环境中，该变量留空。
nomad-client.json中有docker_rpm和docker_cli_rpm两个变量，在不可访问公网的环境中构建nomad-client镜像时，可以把docker-ce和docker-cli的安装包提前上传到该环境可访问的ufile中，并且通过这两个变量传递rpm包地址。脚本在发现有包地址时，会优先下载rpm包安装。

### 安装、配置consul/nomad的systemd服务

这一步会去基础下载地址下载consul和nomad的二进制文件，并配置系统服务。Packer脚本中的consul_version和nomad_version变量指定了您想要安装的版本。在构建之前，您需要确认您想要安装的版本在ufile或者您指定的地址上可以下载。
[consul下载](https://www.consul.io/downloads.html)
[nomad下载](https://www.nomadproject.io/downloads.html)

主要代码在scripts/(consul-service.sh|nomad-service.sh)中
nomad server与nomad client的安装本身是一样的，区别在于配置文件不同。

### 写入配置文件模版
consul server通过scripts/consul-server.sh配置服务器版模版，nomad server与nomad client通过config-consul-agent.sh配置agent版模版。
nomad-server.sh与nomad-client.sh配置各自的nomad配置模版。
请注意，由于构建镜像时我们无法得知具体部署时主机的Ip、名称等信息，所以目前为止写入的配置文件还只是一个模版，需要在具体创建机器后通过sed替换相关内容才能正常工作。

### 安装docker
scripts/install-docker.sh帮助我们从yum源或是我们提供的rpm包安装docker。

### 配置Terraform插件缓存
编排rocketmq运行时需要调用terraform动态绑定弹性ip，并且配置公网ULB及后端，而国内访问Hashicorp的插件仓库速度极慢，所以我们需要在构建Nomad Client镜像时，把相关插件下载配置在主机里，启动rocketmq任务时，terraform就可以直接使用这些插件。
scripts/build-terraform-plugin-cache.sh下载、配置了这些插件，插件会被下载到/plugin下，并通过挂载卷的形式挂载到terraform容器里。packer-scripts/nomad-client.json里的一系列tf_plugin_*变量指定了镜像的版本号。
[Hashicorp官方镜像仓库](https://releases.hashicorp.com/)
我们需要下载的是对应的linux_amd64版本，在这里为了方便起见，我们都先解压缩后上传到了ufile上，所以请确保ufile里保存的是经过解压缩的二进制文件。
