# Nomad集群中的Consul集群

![](http://hashicorpfile.cn-bj.ufileos.com/nomad_public.jpg)

本项目创建的Nomad集群中，有3台Consul服务器，它们的作用有二：
* 提供服务发现功能，帮助Nomad组网、RocketMQ基于Consul Connect组网、基于fabio暴露RocketMQ Http Endpoint
* 提供KV存储服务，保存Broker在public模式下所使用的弹性IP信息及tfstate

Consul Server的数量固定为3（目前不可改变）。

在consul-server/variables.tf中，有一个参数需要说明：var.use_udisk，该参数定义主机是否使用udisk作为数据盘。如果该值为false，则使用本地盘作为数据盘。

首先我们创建一个[硬件隔离组](https://www.ucloud.cn/yun/110085.html)，它可以保障我们的三台Consul服务器落在不同的物理机上（对于跨3可用区部署的情况无需如此，但对于单可用区部署，物理隔离尤其重要）

创建主机的代码里，我们定义了一个比较奇怪的provisioner:
```hcl
provisioner "local-exec" {
    command = "sleep 10"
  }
```
这是因为如果我们数据盘使用的是UDisk，Terraform在创建完主机后会立即创建UDisk以及与主机的attachment，这时uhost主机也刚刚开机。uhost在刚开机时如果立即挂载udisk，会有很大概率导致启动失败，陷入无限等待，导致Terraform无法ssh完成初始化，进而使得整个Terraform执行失败。所以我们在创建主机之后，定义一个provisioner，使得Terraform相关线程sleep 10秒，再尝试创建后续的attachment，可以避免上述问题的发生。

代码中创建完consul_server主机后，我们并没有按照常规，使用Terraform的count创建ucloud_disk和ucloud_disk_attachment数组，而是分为三组独立的资源声明。这是因为当我们把Consul Server/Nomad Server/Nomad Client资源都分成三组之后，三组资源可以彼此不影响地独立更新。例如，我们的集群一开始使用的是UDisk，结果我们运行一段时间后发现需要改成使用本地盘（或者反过来），我们就可以单独更新第一个可用区的所有资源（同时集群还有两个可用区的资源可用，整体可用性不受大的影响），然后单独更新第二个可用区，然后第三个。由于主机是否使用UDisk是由配置的参数决定的，所以我们必须分成三组独立的资源声明。

我们定义了一个local：server_ips，它就是我们准备ssh到主机上用的ip。根据部署模式的不同，它的值也不同：
* test：test模式下我们是通过自己的开发机创建的集群，所以直接使用分配给主机的弹性IP
* public：public模式是我们通过KUN上的pod执行的Terraform，主机不分配公网弹性IP，所以我们必须使用主机内网IP的IPv6版本
* private：private模式下我们也是通过KUN上的pod执行Terraform，但由于内部环境下VPC内网地址从KUN或者管理网直接可达，所以直接使用主机内网地址

代码中我们还会创建一个内网ULB：
```hcl
resource ucloud_lb intenalLb {
  name      = "consulServer-${var.cluster_id}"
  internal  = true
  tag       = var.cluster_id
  vpc_id    = var.vpc_id
  subnet_id = var.subnet_id
}
```

代码中我们独立声明了一个名为"config_consul"的null_resource，这个资源是ssh到创建出来的主机上，渲染consul相关的配置文件的。特别指出，这个resource<strong>绝对不可以改名</strong>，这是因为后续当我们希望滚动升级集群时，能够正确配置整个集群的consul配置，纳入新建的服务器，这一段我们将在后续滚动更新的章节中详细阐述。config_consul首先用一个consul server的配置文件模版覆盖（或是新建）到配置文件的位置，然后通过执行渲染出的一段shell脚本，用sed把模版中相关项替换成terraform创建出来的主机的ip以及主机id。该脚本是幂等的，同一台服务器即使执行多次，产生的配置文件依旧是指向当前有效的服务器配置。

在其后的install_consul_server当中，我们做了三件事：
* 挂载数据盘并启动consul服务
* 添加内网ULB所需要的loopback网卡，配置内网ULB的IP
* 更换ssh host key

因为内网ULB[仅支持报文转发模式](https://docs.ucloud.cn/network/ulb/guide/vserver-xiang-guan-cao-zuo/createvserver)，而报文转发模式需要在后端服务器上[额外配置一块loopback网卡](https://docs.ucloud.cn/network/ulb/guide/fu-wu-jie-dian-xiang-guan-cao-zuo/editrealserver)，
所以我们必须同时渲染一段用来添加loopback卡的shell脚本template_file.add-loopback-script，通过null_resource来ssh到主机上执行。

目前UCloud云主机只会在使用官方镜像启动一个linux主机时更换ssh host key，而使用自定义镜像启动时则不会更换，这就导致了通过同一个自定义镜像启动的所有主机的ssh host key都是一样的，这样的话只要能够使用该镜像创建出一台主机，即可获得所有主机的ssh host key，也就可以对和主机建立的ssh连接发动中间人攻击，所以我们需要在启动每一台服务器的时候刷新它的ssh host key。

如果说还有一点工作，那就是在脚本的末尾部分我们声明了一个名为"ensure_consul_ready"的null_resource。这是因为后续的脚本有时会在创建好consul服务器之后立即尝试与之交互，又或者我们在更新服务器的时候不希望直接把3组服务器中的2组切出更新了，这会导致集群失去quorum而拒绝服务。所以我们在更新或安装consul服务器之后，会执行一段shell脚本，在脚本中循环执行一些consul命令，直到命令执行成功，并且返回集群已经成功选举出一个leader为止。这种方式确保了我们无论是新建，还是更新一个现有集群，当Terraform执行成功之后，集群状态都是立即可用的，这对集群来说是很重要的。

脚本的最后部分是一个名为"finish_signal"的null_data_source，这是因为terraform module目前在新建资源时在graph中实际上是展开的，我们在外部无法[depends_on](https://www.terraform.io/docs/configuration/resources.html#depends_on-explicit-resource-dependencies)一个module，强制terraform在完成了模块中所有资源的创建之后，才继续后续资源的创建。finish_signal的作用就是给module设置了一个结束信号，外部资源只需要depends_on finish_signal就可以确保近似达到depends_on module的目的。
