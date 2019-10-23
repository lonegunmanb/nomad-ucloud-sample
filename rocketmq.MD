# 部署RocketMQ集群


一个典型的RocketMQ集群[架构](https://rocketmq.apache.org/docs/rmq-arc/)中主要分为NameServer与Broker两部分，Broker又分为Master与Slave两种角色

由于传统的RocketMQ Master-Slave部署方式在发生故障时需要手动切换主从关系，在多租户部署模式下会增加运维与故障处理的难度，所以我们采用了[dledger](https://www.infoq.cn/article/f6y4QRiDitBN6uRKp*fq)部署方式：

![](http://hashicorpfile.cn-bj.ufileos.com/rocketmq.jpg)

NameServer之间互相独立，彼此不知晓对方的存在，而三个Broker实例通过在配置文件中配置彼此的IP，相互连接，并用Raft协议选举出主从关系，组成一个Broker Group。

同一组NameServer也可以对接多组Broker Group，实现性能横向扩展：

![](http://hashicorpfile.cn-bj.ufileos.com/rocketmq%20(1).jpg)

所以我们认为，三台NameServer组成的集群是可以独立部署的一个实体，拥有自己的ID；一组三台Broker组成的集群是一个实体，拥有自己独立的ID，并通过接收NameServer集群ID来把自己注册到对应的NameServer上去。要创建一个最小化的RocketMQ集群，我们首先跳转到rocketmq-job-namesvr目录下：
```shell script
terraform init
# 这里NameServer集群ID就是mynamesvr，同一个Nomad集群内必须唯一
terraform workspace new mynamesvr
```
然后我们创建terraform.tfvars.json:
```json
{
  "nomad_cluster_id": "myspace",
  "rocketmq_docker_image": "uhub.service.ucloud.cn/lonegunmanb/rocketmq",
  "rocketmq_version": "4.5.2",
  "terraform-image": "uhub.service.ucloud.cn/lonegunmanb/terraform:0.12.10",
  "golang-image": "uhub.service.ucloud.cn/lonegunmanb/golang:alpine",
  "ucloud_pubkey": "xxxxxxxxxxx",
  "ucloud_secret": "yyyyyyyyyyy",
  "allow_multiple_tasks_in_az": false,
  "ucloud_api_base_url": "https://api.ucloud.cn",
  "remote_state_backend_url": "http://localhost:8500"
}
```
* nomad_cluster_id:Nomad集群ID
* rocketmq_docker_image:
* rocketmq_version:rocketmq_docker_image:rocketmq_version拼接在一起就是rocketmq docker镜像id
* terraform-image:rocketmq任务运行时可能会调用terraform来绑定弹性IP，该变量给出一个含有terraform运行时环境的镜像ID
* golang-image:NameServer运行时会通过go run对外暴露一个http endpoint服务，该变量定义了一个含有golang sdk运行时环境的镜像ID
* allow_multiple_tasks_in_az:该变量为true时，Nomad可能会把3个NameServer调度到同一个可用区里；如果为false，则必须跨3可用区运行；如果您只有一个可用区，可以设置为true

然后执行terraform apply，脚本会创建一组RocketMQ NameServer容器，一个Web控制面板，一个公网ULB，以及对应的后端转发，您会在输出中看到nameSvrLbIp的值。
假设我们用上述配置文件执行后，看到的IP是120.100.0.1,tcp连接120.100.0.1:9876，可以访问NameServer；或者通过http://120.100.0.1:8080/console-mynamesvr 访问Web控制台。

然后让我们跳转到rocketmq-job-broker目录下，一样：
```shell script
terraform init
# 这里Broker Group ID就是mynamesvr，同一个Nomad集群内必须唯一
terraform workspace new broker0
```
然后创建terraform.tfvars.json文件：
```json
{
  "nomad_cluster_id": "myspace",
  "namesvr_clusterId": "mynamesvr",
  "rocketmq_docker_image": "uhub.service.ucloud.cn/lonegunmanb/rocketmq",
  "rocketmq_version": "4.5.2",
  "ucloud_pubkey": "xxxxxxxxxxxxxx",
  "ucloud_secret": "yyyyyyyyyyyyyy",
  "terraform-image": "uhub.service.ucloud.cn/lonegunmanb/terraform:0.12.10",
  "allow_multiple_tasks_in_az": false,
  "ucloud_api_base_url": "https://api.ucloud.cn",
  "remote_state_backend_url": "http://localhost:8500"
}
```
参数基本与NameServer的一致，除了要传入Nomad Cluster ID外，还要传入之前创建的NameServer Cluster ID，执行terraform apply后创建成功。由于Broker启动、组网后会把自身信息写入NameServer，所以创建Broker的脚本不会有返回值。
测试完成后，在销毁Nomad Cluster前，我们也要记得按照顺序，先跳转到rocketmq-job-broker目录下执行terraform destroy，然后是rocketmq-job-namesvr下destroy，把额外申请的公网ULB、弹性IP等资源释放后，再销毁Nomad集群，否则会造成资源的泄漏。

## 参数文件模版

构造一个运行于Nomad上的RocketMQ集群，核心关键在于如何构造配置文件。如果我们手动在云主机上创建一组RocketMQ集群，我们就要构建类似这样一个Broker Config文件：

```text
brokerClusterName = RaftCluster
brokerName=RaftNode00
listenPort=30911
namesrvAddr=127.0.0.1:9876
storePathRootDir=/tmp/rmqstore/node00
storePathCommitLog=/tmp/rmqstore/node00/commitlog
enableDLegerCommitLog=true
dLegerGroup=RaftNode00
dLegerPeers=n0-172.18.0.12:40911;n1-172.18.0.13:40912;n2-172.18.0.14:40913
## must be unique
dLegerSelfId=n0
sendMessageThreadPoolNums=16
```

比较关键的配置项：
* namesrvAddr：NameServer的IP和端口
* dLegerGroup：Broker Group ID
* dLegerPeers：三台Broker的IP和端口

可惜，这种手动配置的方式我们无法直接使用，原因是因为Nomad不提集群网络功能功能。

## 服务发现

Nomad与Kubernetes相比，架构上简化了许多，最明显的区别是Nomad本身不提供任何集群网络功能，只是简单的容器和任务的调度，不同于K8S每一个Pod都可以有独立的IP和DNS Name以及K8S Service可以对外暴露服务。这就导致Nomad中的容器只能使用宿主机IP与端口对外提供服务，使我们无法在配置文件中使用固定的IP与端口来组网。

另外集群中的机器可能会发生故障导致容器漂移，漂移后的宿主机IP与端口号都会发生变化。我们需要一种稳定的方式，帮助Broker彼此连接，以及连接到NameServer。

本项目使用的是基于[Consul Connect](https://www.consul.io/docs/connect/index.html)的Service Mesh。

![](http://hashicorpfile.cn-bj.ufileos.com/Consul%20Connect.jpg)

简单来说，每一个NameServer和Broker容器通过Nomad调度器启动时，我们都在Consul上注册一个对应的服务，并且在宿主机上启动一个Consul Agent进程作为Sidecar。对Broker来说，其他Broker以及NameServer是在localhost上的，可以通过一个localhost上的端口来访问；如果容器由于故障转移发生了漂移，那么在容器恢复运行后，其他容器仍然可以通过他们宿主机上同样的localhost加端口号访问到这个新启动的容器。

实现这一点的关键代码在rocketmq-job-broker/broker-job.hcl.tplt里渲染broker.conf的地方：
```text
brokerClusterName = {{ env "NOMAD_META_clusterId" }}
brokerName=broker-{{env "NOMAD_META_clusterId"}}
{{$internal := env "NOMAD_META_internal"}}
{{if ne $internal ""}}
  brokerIP1={{env "meta.hostIp"}}
{{else}}
  {{$allocId := env "NOMAD_ALLOC_INDEX"}}
  brokerIP1={{key (printf "brokerEip/${cluster-id}/eip/%s" $allocId)}}
{{end}}
listenPort={{ env "NOMAD_PORT_broker" }}
namesrvAddr={{range $i := loop ((env "NOMAD_META_namesrvCount")|parseInt)}}{{if ne $i 0}};{{end}}localhost:{{env (printf "NOMAD_PORT_outboundProxy_namesvrTcp%d" $i)}}{{end}}
storePathRootDir=/data
storePathCommitLog=/data/commitlog
enableDLegerCommitLog=true
dLegerGroup={{ env "NOMAD_META_clusterId" }}
dLegerPeers={{range $i := loop ((env "NOMAD_META_brokerCount")|parseInt)}}{{$index := (env "NOMAD_ALLOC_INDEX")|parseInt}}{{if ne $i 0}};{{end}}n{{$i}}-{{if ne $i $index}}localhost:{{env (printf "NOMAD_PORT_outboundProxy_dledger%d" $i)}}{{else}}{{env "NOMAD_ADDR_dledger"}}{{end}}{{end}}
## must be unique
dLegerSelfId=n{{ env "NOMAD_ALLOC_INDEX" }}
sendMessageThreadPoolNums=16
clientCloseSocketIfTimeout=true
flushDiskType=ASYNC_FLUSH
```
在这里namesrvAddr与dLegerPeers是通过[Consul Template](https://github.com/hashicorp/consul-template)渲染的，在Nomad启动容器时，会把任务对应的Consul Connect Proxy端口渲染进配置文件，使得Broker通过Sidecar来互相连接。模版中使用了一些[Nomad变量](https://www.nomadproject.io/docs/runtime/interpolation.html)

一个入门级的Consul Connect + Nomad的例子在[这里](https://www.consul.io/docs/connect/platform/nomad.html)，最新版本的Nomad中引入了[更加简化的写法](https://www.nomadproject.io/docs/job-specification/proxy.html)，但本项目编写时还无法使用简化写法。

## 构造brokerIP1的逻辑
这里的brokerIP1就是broker向name server注册自己时用的IP，这里我们的模版是：
```text
{{$internal := env "NOMAD_META_internal"}}
{{if ne $internal ""}}
  brokerIP1={{env "meta.hostIp"}}
{{else}}
  {{$allocId := env "NOMAD_ALLOC_INDEX"}}
  brokerIP1={{key (printf "brokerEip/${cluster-id}/eip/%s" $allocId)}}
{{end}}
```
我们在启动一个broker集群的Nomad任务时，会根据env_name(test/public/private)设置任务的元数据"internal"，如果是private部署，这个值就是"true"，否则是空字符串。
模版如果发现该值不是空字符串，那么注册的IP就是自身的内网IP（meta.hostIp是通过Terraform创建一台Nomad Client时渲染到Client配置文件里的，它的值就是机器的内网IP），否则就是通过Consul KV读取属于自己的弹性IP。

## 构造dLegerPeers的逻辑

rocketmq通过dLeger模式组网的方式是，把三个broker的ip和端口以这样的形式拼起来：
```text
dLegerPeers=n0-172.18.0.12:40911;n1-172.18.0.13:40912;n2-172.18.0.14:40913
```
然后根据自身配置的dLegerSelfId的值来判断broker该侦听的ip与端口，比如：
```text
dLegerSelfId=n0
```
如果配置文件中dLegerSelfId是n0，那么broker启动后会尝试侦听172.18.0.12:40911这个地址。

我们下面把模版中dLegerPeers的部分格式化后详细讲解一下（这段比较复杂）：
```text
//循环计数0-2
{{range $i := loop ((env "NOMAD_META_brokerCount")|parseInt)}}
    //NOMAD_ALLOC_INDEX变量代表当前这个容器在3个broker中的序号，从0开始
    {{$index := (env "NOMAD_ALLOC_INDEX")|parseInt}}
        //不是第一个元素的话，拼接一个;
        {{if ne $i 0}};{{end}}
        //n0-/n1-/n2-
        n{{$i}}-
        //如果这个broker不是自己，那么拼接localhost上对应的Sidecar的端口
        {{if ne $i $index}}
            localhost:{{env (printf "NOMAD_PORT_outboundProxy_dledger%d" $i)}}
        {{else}}
        //否则拼接容器自身所在宿主机IP和属于dledger的端口
            {{env "NOMAD_ADDR_dledger"}}
        {{end}}
{{end}}
```

因为broker根据dLegerSelfId来决定自己侦听dLegerPeers中的哪一段地址，所以如果三个地址都是Sidecar的地址会导致broker试图侦听属于Sidecar的端口（这会造成端口冲突），所以当判定这一段是自己的时候，一定要用分配给broker dleger的宿主机IP和端口。

## 数据存储的设置
我们在配置文件中有这样的配置：
```text
storePathRootDir=/data
storePathCommitLog=/data/commitlog
```
每一台Nomad Client启动时，都会把数据盘（本地盘或者是UDisk）挂载到/data，broker容器启动时，Nomad会为它分配一个[专属文件夹](https://www.nomadproject.io/docs/runtime/environment.html#task-directories)。我们已经配置Nomad Client，把这些专属文件夹都分配在数据盘下，启动broker容器时，会把这个专属文件夹下的data文件夹挂载到容器的/data路径下，这样就能确保broker的数据都是写入宿主的数据盘。

Nomad Client有GC机制，会把Complete/Failed的任务的专属文件夹[GC](https://github.com/hashicorp/nomad/pull/2081)掉。所以如果用户决定删除自己的RocketMQ集群，相关Nomad任务停止一段时间后，GC会把磁盘上Broker写入的文件逐渐删除，释放空间。

## clientCloseSocketIfTimeout
因为broker之间，以及broker和name server之间都是通过Sidecar连接的，所以如果一个容器发生了漂移，其他的容器是无法感知到地址发生了变化的。如果clientCloseSocketIfTimeout=false，那么容器发生漂移后，其他容器到死亡容器的tcp连接实际上还存在，只是处于半开状态，这时容器不会尝试重建连接，也就无法和新启动的容器建立连接。所以在这里我们必须设置clientCloseSocketIfTimeout=true

## 小结

由于Nomad缺乏像K8S那样强大的网络功能，无法给每个Pod分配一个稳定的访问地址（StatefulSet/DNS），所以我们必须为NameServer/Broker服务配置对应的Consul Connect Sidecar进程，彼此之间通过Sidecar连接，这样即使发生故障转移，容器漂移，对没有发生故障的容器来说网络拓扑结构看起来也没有变化。
