# Nomad集群网络简介

根据Hashicorp Nomad官方网站的介绍，Nomad的定义如下：
>Nomad is a flexible workload orchestrator that enables an organization to easily deploy and manage any containerized or legacy application using a single, unified workflow. Nomad can run a diverse workload of Docker, non-containerized, microservice, and batch applications.

![](http://hashicorpfile.cn-bj.ufileos.com/nomad_reference_diagram-72c969e0.png)

上图是一个典型的Nomad集群部署架构。Nomad本身可以直接通过IP和端口组建集群，但我们推荐使用Consul作为注册中心，这样我们就可以在Nomad上使用许多基于Consul提供的功能。

## Cluster ID

本项目支持在任意Region部署任意多彼此独立的集群，每个集群都要有一个独一无二的Cluster ID，这个Cluster ID会被赋值给所有资源所属的业务组，并且创建的资源名称中会带有Cluster ID。由于本项目代码中有一部分完全依赖按名字查询资源ID，所以不通集群之间Cluster ID必须不同，同一Region下不允许出现多个集群共用同一Cluster ID的现象。

## Nomad网络结构

根据实际情况，我们采用跨3可用区部署的方式来获得高可用性，实际部署时Nomad集群如下：
![](http://hashicorpfile.cn-bj.ufileos.com/nomad_public.jpg)

Consul服务器固定为3台，Nomad Server根据集群规模可以>=3台，另外Nomad Client又分为NameServer与Broker两种。由于RocketMQ的特性，所以NameServer服务器不需要配置高性能硬盘，只需要磁盘能够容纳被调度运行的任务数据即可。

Consul/Nomad Server/NameServer三种服务器都有一个属于各自的内网ULB，Terraform脚本会保障内网可以通过这些内网ULB访问到后端某台服务器，这样后续我们可以通过KUN上的Service直接访问到Consul/Nomad服务，或是通过NameServer上的一些系统任务，与集群中的RocketMQ实例互动。

* [Consul推荐服务器配置](https://learn.hashicorp.com/consul/datacenter-deploy/reference-architecture)
* [Nomad推荐服务器配置](https://www.nomadproject.io/guides/install/production/reference-architecture.html#system-reqs)

Consul服务器之间通过scripts/consul-server.sh里的配置互相认识：
```hcl
retry_join = ["CONSUL_SERVER1_IP", "CONSUL_SERVER2_IP", "CONSUL_SERVER3_IP"]
```
Nomad Server与Nomad Client通过scripts/config-consul-agent.sh中的配置首先连接到consul，然后再通过consul互相认识、组网：
```hcl
retry_join = ["CONSUL_SERVER1_IP", "CONSUL_SERVER2_IP", "CONSUL_SERVER3_IP"]
```

Consul的组网除了使用Ip，还可以通过[Cloud Auto Join](https://www.consul.io/docs/agent/cloud-auto-join.html)
笔者向Hashicorp提交了UCloud的Cloud Join实现，该[PR](https://github.com/hashicorp/go-discover/pull/126)目前仍未review，如果成功合并，那么就可以通过[这种方式](https://github.com/lonegunmanb/go-discover/blob/ucloud/README.md)配置，借助vpc_id、subnet_id和tag自动发现consul服务，并且组网。

Nomad集群部署在UCloud上，UCloud VPC结构如下：
![](http://hashicorpfile.cn-bj.ufileos.com/network.jpg)

我们会创建两个VPC与对应的子网，并且打通这两个VPC。我们在client vpc上声明一个Nat网关，配置一个公网IP，这样Nomad Client中的容器就可以通过Nat网关访问到公有云API。

为什么是两个VPC？考虑到未来用户可能会要求通过内网访问消息队列，那时我们可以把Nomad Client所在的VPC（也就是RocketMQ容器所在的VPC）与客户VPC打通，这样就可以内网访问了，同时Consul Server/Nomad Server控制面在另一个VPC里，与客户VPC保持隔离。

部署private模式时，由于我们不能创建、销毁VPC，并且无法发访问外网，只能使用管理员预设的VPC，所以网络结构如下：
![](http://hashicorpfile.cn-bj.ufileos.com/private_network.jpg)

通过terraform创建network文件夹下的网络栈时，如果传入了legacy_vpc_id以及legacy_subnet_id，那么就只会使用传入的vpc与子网；否则，则新建。
