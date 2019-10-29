# 滚动更新

集群投产后，如果需要更新（升级主机配置/修复系统补丁/升级Consul、Nomad版本），我们准备采用的是基于[不可变基础设施](https://linux.cn/article-6173-1.html)模式的滚动更新方式。

可变基础设施的更新就是我们或手动或通过ansible这样的自动化工具登陆服务器，修改配置文件，更新可执行文件与环境，修改已有的资源状态来完成更新。可变基础设施的一个问题是我们无法确切地知道生产环境机器的状态，我们无法100%精确复制出一个与生产环境完全等价的环境。对生产环境的修改本身也很难被版本化控制，久而久之可能会造成"雪花服务器"（世界上没有两片相同的雪花）

![](http://hashicorpfile.cn-bj.ufileos.com/phoenix-snowflake_comic_r2_1490x3020.png)

不可变基础设施简单来说，就是系统一旦投产，对系统的变更只能通过自动化系统和交付流水线，并且只能通过更新主机镜像、容器镜像的方式来进行更新。在K8S中非常容易做到这一点，我们不会想到通过登陆容器，在容器中更换可执行文件，修改配置文件来实现更新，我们只会修改yaml中的容器ID，然后apply，让K8S把老的Pod逐步替换成新的容器。

对于我们部署的这个集群来说，我们要做的也是一样的，更新只能通过新版本packer代码->新版本镜像->新版本生产环境的方式执行。
由于UCloud公有云并没有[K8S Deployment的RollingUpdateStrategy](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#updating-a-deployment)或是[AWS AutoScaling UpdatePolicy](https://docs.aws.amazon.com/zh_cn/AWSCloudFormation/latest/UserGuide/aws-attribute-updatepolicy.html)这样的强大工具，我们并没有开箱即用的蓝绿发布、滚动更新、灰度发布等可用，所以我们必须自己实现不可变风格的滚动更新。

普通的主机变更（升降级配置，修改密码）目前Terraform UCloud Provider都可以做到In Place Update(不重建，直接变更主机属性，最多关机后重新启动)，对改名、改tag的操作更加是可以不停机变更，但只有在变更image id时会遇到一个[主机的问题](https://ushare.ucloudadmin.com/pages/viewpage.action?pageId=20368433)，导致Terraform无法感知主机的image id发生了变化。

所以我们要更新主机，必须使用[Terraform Taint](https://www.terraform.io/docs/commands/taint.html)。taint命令就是在tfstate中将某个资源标注为必须删除重建。我们的滚动更新主要做的就是将集群中一部分机器用taint命令标记，然后执行terraform apply，这时Terraform会把被标记的资源全部删除重建。

如果我们把Nomad Server和Nomad Client声明为一个模块，使用同一组参数，那么即使我们只标注了其中一部分的资源，但是由于参数发生变化，还是会影响到所有资源（例如升级了机器配置变量，无论是否被标记，所有使用了该变量的机器都会被更新，被标记的机器是被删除重建，而没被标记的机器则是关机升级）

为了明确地区分机器，控制参数变更的爆炸半径所以我们把Nomad Server和Nomad Client显式声明为3组，使用长度为3的参数数组来定义每组的配置。我们只需要严格确保每次更新只升级一个组，集群的可用性都是有保障的。

手动标记要taint的资源会比较麻烦，也容易出错，所以我们提供了rolling-update工具来帮助我们做标记和apply的工作。

我们要滚动更新的目标有三种类型，Consul Server、Nomad Server，以及Nomad Client（Nomad Client又分为NameServer以及Broker，只不过它们在滚动更新时执行的操作是完全相同的）。
这三种类型的资源在滚动更新时有着略微不同的策略

## Nomad Server
Nomad Server在声明时就分成了三个module：nomad_server0、nomad_server1、nomad_server2，所以taint的策略就是把相应module内所有的resource标记taint。

## Nomad Client
Nomad Client在声明时分成了六个module：nameServer0、nameServer1、nameServer2、broker0、broker1、broker2，同样的，我们要taint掉某个具体module内的所有资源；
另外，在taint资源主机的同时，我们还要做额外的两个工作
* [设置节点可用性](https://www.nomadproject.io/docs/commands/node/eligibility.html)，使得新提交的任务不会再被调度到这些注定要被删除的机器上
* [驱逐任务](https://www.nomadproject.io/docs/commands/node/drain.html)，将这些机器上的任务标定为立即重新调度到其他机器上

由于Nomad发现任务健康检查失败到决定重新调度还要等待一段时间，所以提前主动驱逐任务可以缩短任务被重新调度的时间。

## Consul Server

Consul Server自身需要使用自身3台服务器的IP地址，所以无法写成3个模块。consul_servers 中的consul_server资源是一个长度为3的ucloud_instance数组，我们要把对应的元素taint掉。

另外，由于所有的Consul Server、Nomad Server、Nomad Client都是通过在配置文件中配置3台Consul Server的IP来组网的，所以当我们删除重建某一台Consul Server之后，我们必须确保所有服务器配置中Consul Server IP也会被更新。
我们在解释Consul Server模块时提到过，名为"config_consul"的null_resource绝对不可以改名，这是因为所有的Consul Server/Nomad Server/Nomad Client模块中，都是用名为"config_consul"的null_resource来配置Consul Server IP的。在这里我们除了要taint掉Consul Server模块里某台主机及其相关资源之外，还要把整个集群里名为"config_consul"的null_resource都taint掉，强迫Terraform把所有服务器的Consul配置刷新到最新版本。

## 如何标注目标资源

terraform提供了一个命令：[show](https://www.terraform.io/docs/commands/show.html),它可以输出当前目录下对应的tfsate描述的资源，利用它以及一些grep，我们就可以筛选出某个模块内的所有资源。

如果我们在根目录下执行完terraform apply后，执行以下命令：
```shell script
root# terraform show | grep '#'
# module.broker1.data.null_data_source.finish_signal:
# module.broker1.data.template_file.consul-config[0]:
# module.broker1.data.template_file.consul-config[1]:
# module.broker1.data.template_file.consul-config[2]:
# module.broker1.null_resource.config_consul[0]:
# module.broker1.null_resource.config_consul[1]:
# module.broker1.null_resource.config_consul[2]:
# module.broker1.null_resource.setup[0]:
# module.broker1.null_resource.setup[1]:
# module.broker1.null_resource.setup[2]:
# module.broker1.ucloud_instance.nomad_clients[2]:
# module.broker1.ucloud_instance.nomad_clients[0]:
# module.broker1.ucloud_instance.nomad_clients[1]:
# module.nameServerid0.data.local_file.output:
# module.nameServerid0.local_file.input:
# module.nameServerid2.data.local_file.output:
# module.nameServerid2.local_file.input:
# module.nameServer2.data.null_data_source.finish_signal:
# module.nameServer2.data.template_file.consul-config[0]:
# module.nameServer2.data.template_file.consul-config[1]:
# module.nameServer2.data.template_file.consul-config[2]:
......
```
我们大概会看到类似这样的输出。通过对字符串进行匹配，就可以筛选出目标资源进行标注。

## 基于go语言的taint helper

项目文件夹下的rolling-update下是一些用go和shell编写的taint helper。rolling文件夹里是共享的代码，rolling-consul/rolling-namesvr/rolling-nomad-server三个文件夹中是用shell编写的入口脚本，rolling-update下的rolling_client.go/rolling_consul.go/rolling_nomad_server.go是三个含有main方法的go执行入口。
* rolling-broker：在rolling-broker内执行sh rolling.sh ${group}(0-2) ${origin_password}(用来ssh即将被删除的主机执行驱逐、leave等操作，如果配置文件中改了新的密码，这里也要传老的密码，因为现存的机器还是使用旧密码) ${dry}(只要有第三个参数，无论什么内容，都视为dry run，这时不会真正执行taint，仅打印会执行的taint操作供参考)
* rolling-consul：在rolling-consul内执行sh rolling.sh ${group} ${origin_password} ${dry}
* rolling-namesvr：在rolling-namesvr内执行sh rolling.sh ${group} ${origin_password} ${dry}
* rolling-nomad-server：在rolling-nomad-server内执行sh rolling.sh ${group} ${dry}

注意，因为nomad server要执行[force leave](https://www.nomadproject.io/docs/commands/server/force-leave.html)命令必须要明确知道节点名称，这对滚动更新脚本来说比较麻烦，所以更新nomad server前我们就不再执行什么操作了。

这些shell脚本基本上就是把要更新的模块名称、组号等通过go run启动taint助手并且传入（开发机是mac，生产环境是linux，不想麻烦维护不同系统的二进制文件，所以决定直接用go run运行代码，这就要求发动滚动更新的环境必须要有go sdk）

根据3类模块各自的taint策略，和删除前要执行的命令的不同，我们在rolling-update/rolling/rolling.go中定义了两种接口：
```go
type RemoteCleanupOnLeave interface {
	OnLeave()
}

type Taint interface {
	Match(res string) bool
}
```

每个模块都有对应的含有main方法的go代码，它们各自根据需要实现了Taint接口。在统一的Taint执行代码里：
```go
func ExecuteTaint(taintPolicy Taint) {
	if onLeave, ok := taintPolicy.(RemoteCleanupOnLeave); ok && !DryRun {
		onLeave.OnLeave()
	}
	res := GetAllRes()
	for _, r := range res {
		if taintPolicy.Match(r) {
			println(fmt.Sprintf("terraform taint %s", r))
			if !DryRun {
				_, _ = ExecCmd(fmt.Sprintf("terraform taint %s", r), Dir, os.Stdout, os.Stderr)
			}
		}
	}
}
```
首先我们会看是不是要在删除前登陆服务器执行一些操作（是否实现了RemoteCleanupOnLeave接口），如果是，就执行这些操作；
其次执行terraform show，并把资源名称解析成一个string slice，交给接口去match，如果match的，就通过命令行taint。

在相关资源都被taint之后，在shell脚本的最后执行terraform apply，就会把被taint的资源删除、重建了。

## 例子

假设我们原来的tfvars文件里是：
```json
{
  ...
  "nomad_client_broker_image_id": ["uimage-a4xefk1d","uimage-a4xefk1d","uimage-a4xefk1d"],
  ...
}
```
我们想把镜像升级到uimage-w54t12k3，那么我们先把tfvars改成：
```json
{
  ...
  "nomad_client_broker_image_id": ["uimage-w54t12k3","uimage-a4xefk1d","uimage-a4xefk1d"],
  ...
}
```
跳转到rolling-update/rolling-broker下执行：
```shell script
sh rolling.sh 0 youroriginpassword
```

等待执行完成后，您会发现第一组broker服务器都被更新到了最新的镜像版本，当然，原来运行在第一组服务器上的任务都会被重新调度到新机器上执行，rocketmq broker会从它的两个伙伴那里重新同步数据。

我们我们还没有工具去监控某一组服务器上的broker是否都已经追上了数据同步进度，简单起见，早期两组服务器更新之间应有一段时间的间隔，防止数据尚未同步完成就把所有服务器都更新了，导致数据丢失。

## 清除被淘汰的机器信息

当我们用rolling-update更新了某组机器后，原先的机器会被删除，在Nomad的控制台上我们会看到死去的机器：
![](http://hashicorpfile.cn-bj.ufileos.com/dead_node.png)

我们可以利用[Nomad GC](https://www.nomadproject.io/api/system.html#sample-request)，向Nomad的访问地址发起一个这样的Http PUT调用。
![](http://hashicorpfile.cn-bj.ufileos.com/after_gc.png)

需要注意的是，GC同时也会触发Nomad Client上开始清理状态为Complete或是Dead的Job，这意味着Nomad Client会开始删除已经不用的RocketMQ Broker Commit Log。
