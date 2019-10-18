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

以上是如何创建一个测试用集群的过程。如果我们手动在云主机上创建一组RocketMQ集群，我们那主要是要构建这样一个Broker Config文件：

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

可惜，这种手动配置的方式我们无法直接使用。

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
在这里namdsrvAddr与dLegerPeers是通过[Consul Template](https://github.com/hashicorp/consul-template)渲染的，在Nomad启动容器时，会把任务对应的Consul Connect Proxy端口渲染进配置文件，使得Broker通过Sidecar来互相连接。

一个入门级的Consul Connect + Nomad的例子在[这里](https://www.consul.io/docs/connect/platform/nomad.html)，最新版本的Nomad中引入了[更加简化的写法](https://www.nomadproject.io/docs/job-specification/proxy.html)，但本项目编写时还无法使用简化写法。
