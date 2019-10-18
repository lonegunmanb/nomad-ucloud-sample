#构建test模式集群

在个人开发机上可以构建出一个测试用的集群，分为两步：
* 构建网络
* 构建集群

生产环境构建集群，要防止tfstate文件由于硬件故障丢失，所以会预先创建一组(3台)consul服务器作为backend，后续集群以及创建出来的RocketMQ集群的状态信息都会保存在这组consul服务上。要在自己的机器上构建测试集群，我们也需要有consul作为backend，但我们可以直接使用dev模式，您可以在自己的机器上[安装](https://learn.hashicorp.com/consul/getting-started/install) consul，然后执行：
```shell script
consul agent -dev
```

就可以在http://localhost:8500上获得可用的consul backend服务。

## 构建网络

转至network文件夹，新建terraform.tfvars.json：
```json
{
  "region": "cn-sh2",
  "ucloud_pub_key": "xxxxx",
  "ucloud_secret": "yyyy",
  "project_id": "org-xxxx",
  "ucloud_api_base_url": "https://api.ucloud.cn",
  "mgrVpcCidr": "10.0.1.0/24",
  "clientVpcCidr": "10.0.2.0/24",
  "legacy_vpc_id": "uvnet-xxxxxx",
  "legacy_subnet_id": "subnet-yyyy"
}
```

如果legacy_vpc_id与legacy_subnet_id不为空，则会无视mgrVpcCidr与clientVpcCidr规划的网段划分，直接使用现存网络。

首先执行init
```shell script
terraform init
```

等待插件下载完毕后，创建一个新的[workspace](https://www.terraform.io/docs/commands/workspace/index.html)。请特别注意，这个workspace名称就是您要创建的集群的Cluster ID。<strong>务必保障</strong>该名称在该region下是唯一的。

```shell script
#这里我们的Cluster ID就是myspace
terraform workspace new myspace
```

然后您可以执行plan观察执行计划
```shell script
terraform plan
```

或是直接执行terraform apply
```shell script
terraform apply
```

确认执行计划如预期的话，您就可以继续执行。执行成功的话，会看到outputs.tf中定义的output值在控制台上被输出了。

## 构建集群

跳转至根目录下，创建terraform.tfvars.json：
```json
{
    "allow_ip": "0.0.0.0/0",
    "az": [
        "cn-sh2-01",
        "cn-sh2-02",
        "cn-sh2-03"
    ],
    "consul_server_image_id": ["uimage-isrn30xf"],
    "consul_server_root_password": ["xxx"],
    "consul_server_type": ["n-highcpu-1"],
    "nomad_client_broker_type": ["n-standard-2"],
    "nomad_client_broker_image_id": ["uimage-nb1xtbtm","uimage-nb1xtbtm","uimage-nb1xtbtm"],
    "nomad_client_namesvr_image_id": ["uimage-nb1xtbtm","uimage-nb1xtbtm","uimage-nb1xtbtm"],
    "nomad_client_namesvr_type": ["n-standard-2"],
    "nomad_client_broker_root_password": ["xxx","xxx","xxx"],
    "nomad_client_namesvr_root_password": ["xxx"],
    "nomad_server_image_id": ["uimage-ldmppbf5","uimage-ldmppbf5","uimage-ldmppbf5"],
    "nomad_server_root_password": ["xxx"],
    "nomad_server_type": ["n-highcpu-1","n-highcpu-1","n-highcpu-1"],
    "project_id": "org-ttq14t",
    "region": "cn-sh2",
    "ucloud_pub_key": "xxxxxxxxxxx",
    "ucloud_secret": "yyyyyyyyyyyy",
    "ipv6_server_url": "http://internal.api.ucloud.cn",
    "region_id": "1000009",
    "broker_count": [1, 1, 1],
    "name_server_count": [1,1,1],
    "nomad_server_count": [1,1,1],
    "name_server_local_disk_type": ["local_normal"],
    "name_server_udisk_type": ["data_disk"],
    "name_server_data_disk_size": [20],
    "broker_local_disk_type": ["local_ssd"],
    "broker_udisk_type": ["data_disk"],
    "broker_data_disk_size": [20],
    "name_server_use_udisk": [true],
    "broker_use_udisk": [true],
    "nomad_server_use_udisk": [true],
    "nomad_server_local_disk_type": ["local_ssd"],
    "nomad_server_udisk_type": ["data_disk"],
    "nomad_server_data_disk_size": [20],
    "consul_server_data_disk_size": [20],
    "consul_server_local_disk_type": ["local_ssd"],
    "consul_server_udisk_type": ["data_disk"],
    "consul_server_use_udisk": [false],
    "namesvr_http_endpoint_port": 8080,
    "prometheus_port": 9090,
    "client_charge_type": ["dynamic"],
    "client_charge_duration": [1],
    "env_name": "test",
    "ucloud_api_base_url": "https://api.ucloud.cn",
    "remote_state_backend_url": "http://localhost:8500"
}
```

参数非常多，让我们选一些来解释：
* allow_ip 公网防火墙放行的source ip(可以访问ssh/nomad/consul/prometheus)
* az 部署的可用区列表（长度严格等于3，如果该region仅有一个可用区可用，那么3个az可以一样）
* consul_server_image_id consul server的镜像id，从Packer构建的结果中获取。需要注意的是，和下面许多的变量一样，由于我们跨三可用区部署，我们希望能够独立更新单个可用区的资源，这样可以按照可用区的粒度对集群进行滚动升级，所以与主机相关的参数都是数组。如果数组长度为1，意为3个可用区使用相同的参数；如果参数需要不同（比如准备升级镜像版本），则参数数组长度严格等于3。
* consul_server_root_password consul server的root账号口令
* consul_server_type consul server的[主机型号](https://www.terraform.io/docs/providers/ucloud/appendix/instance_type.html)
* nomad_client_broker_image_id broker宿主机的镜像id
* project_id ucloud项目id
* region 创建集群所在的区域
* region_id 通过[cmdb](https://cmdb-web.ucloudadmin.com/category/Location)查询区域对应的region_id,如广州 RegionId 为 1000003，上海2 RegionId 为 1000009
* ipv6_server_url 从KUN上访问用户网服务必须将VPC中的ipv4内网地址转换成ipv6，转换api默认地址是http://internal.api.ucloud.cn
* broker_count broker 宿主机的数量，长度为3的数组，代表每个可用区里borker宿主机的数量。
* broker_use_udisk broker宿主机是否使用udisk作为数据盘
* broker_data_disk_size broker宿主机数据盘大小，注意[尺寸限制](https://www.terraform.io/docs/providers/ucloud/r/instance.html#data_disk_size) ,机械udisk最大8T，SSD udisk最大4T，本地机械盘最大2T，本地SSD最大1T
* broker_udisk_type 如果配置broker使用udisk作为数据盘，[udisk的类型](https://www.terraform.io/docs/providers/ucloud/r/disk.html#disk_type)
* broker_local_disk_type 如果配置broker使用本地盘作为数据盘，[本地盘的类型](https://www.terraform.io/docs/providers/ucloud/r/instance.html#data_disk_type) ，需要特别注意，所有主机的系统盘类型，快杰云主机强制使用ssd udisk；如果数据盘是udisk，那么系统盘就是本地ssd盘；如果数据盘是本地盘，那么系统盘类型采用数据盘的类型。
* namesvr_http_endpoint_port name server宿主机对外暴露索引服务的静态端口，[建议使用8080](https://rocketmq.apache.org/docs/best-practice-namesvr/)
* prometheus_port name server宿主机上对外暴露的prometheus服务端口，建议使用9090
* client_charge_type 资源[付费模式](https://www.terraform.io/docs/providers/ucloud/r/instance.html#charge_type)
* client_charge_duration 资源[付费时长](https://www.terraform.io/docs/providers/ucloud/r/instance.html#duration)
* env_name 部署模式，在这里我们使用"test"
* ucloud_api_base_url ucloud api地址
* remote_state_backend_url 使用的terraform backend地址

这当中与机器等资源相关的参数都是数组，长度为1或者3，["n-highcpu-1"]等同于["n-highcpu-1"， "n-highcpu-1"， "n-highcpu-1"]

随后依然是init后apply:
```shell script
terraform init
#务必确保使用与创建network时相同的Cluster ID——myspace
terraform workspace new myspace
terraform apply
```

就可以创建出一个测试用的集群，在输出中寻找nomad_server_access_url，可以看到创建出来的nomad集群控制台。

您可以通过执行：
```shell script
terraform output -json | jq -r '.nomad_server_access_url.value'
```
直接输出该地址

测试完成后，我们可以在根目录下执行：
```shell script
terraform destroy
```

然后跳转到network文件夹，重复执行destroy，即可销毁所有创建出来的资源

##注意点

* 必须严格遵循创建network->创建集群的顺序，没有创建network的情况下创建集群会报错
* 创建过程中如果看到"<span style="color:blue">Failed to retrieve raft configuration: Unexpected response code: 500 (No cluster leader)</span>"的报错，属于正常情况，这是在创建了nomad server后，远程ssh执行一段shell脚本，阻塞至nomad选举leader成功。所以当创建脚本执行完成后，该集群是可以直接提交工作任务的。
* 由于UCloud VPC目前存在一个问题，导致如果我们如果在新建的vpc和subnet中创建了集群，那么即使我们销毁了整个集群，我们也无法删除vpc与subnet，UCloud依然会认为子网中还存在其他资源，需要等待10-15分钟后才能删除。如果您通过设置legacy_vpc_id和legacy_subnet_id使用已经存在的vpc和subnet，则destroy时不会尝试删除，也就不会报错。
* UCloud公网防火墙在同一region下不允许出现同名防火墙，所以如果您尝试在一个region创建两个Cluster ID相同的集群，将会报错。
