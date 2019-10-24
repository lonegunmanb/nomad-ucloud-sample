# 系统任务

Nomad中有一种[System Job](https://www.nomadproject.io/docs/schedulers.html#system)类型的Job，类似K8S的DaemonSet，Nomad会在每一个符合Job中定义的约束的Client节点上启动相同的Job。

我们在system-job文件夹中定义了三组Job
* namesvrIndexFabio：为了在private模式下对外提供NameServer Http Endpoint的Fabio服务
* prometheus_job：这是一个普通[Service类型](https://www.nomadproject.io/docs/schedulers.html#service)的Job，负责收集Nomad Server/Nomad Client/Consul Server的prometheus标准metric
* prometheus_fabio：为了能让外部访问到prometheus_job的服务而配置的Fabio服务

我们希望RocketMQ NameServer相关的服务与Prometheus的服务能够在不同的端口上提供，在Consul中以不同的urlprefix注册，减少彼此的关联，所以我们部署了两个Fabio容器，侦听8080和9090端口，通过NameServer所属的内网ULB对外暴露服务。

## NameServer Index相关任务

我们在[system-job/main.tf](main.tf#L6)定义了namesvr_index_http_endpoint，它会启动一个Fabio System Job，在每台NameServer宿主机上启动Fabio镜像，并且配置好urlprefix，后续属于RocketMQ NameServer Index的Consul Service一启动，Fabio就会自动添加路由，这样通过NameServer内网ULB，我们可以访问到任意RocketMQ集群的NameServer Index服务。

## Prometheus相关任务

### 配置Consul输出Prometheus

Consul要配置输出Prometheus标准监控数据可以在[配置文件](https://www.consul.io/docs/agent/options.html#telemetry-prometheus_retention_time)中声明。
在[scripts目录下consul-server.sh](../scripts/consul-server.sh#L17)里我们声明了输出：
```text
prometheus_retention_time = "10s"
```
任何大于"0s"的设置都会启动prometheus exporter。

由于Consul启动后，只会把自身8300端口rpc服务注册到service里，而prometheus需要通过http的8500端口访问，为了让prometheus能够通过consul service查询到consul prometheus地址，所以我们在consul-server.sh里还声明了一个文件：
```text
cat>/etc/consul.d/consul_service.json<<-EOF
{
  "service": {
    "name": "consul_http",
    "port": 8500,
    "tags": ["cluster-CLUSTER", "http"]
  }
}
EOF
```
这段代码在Packer构建Consul Server镜像时被执行，Consul启动后会把自身http的访问地址也注册到service里，这样后续prometheus就可以发现它们。

### 配置Nomad输出Prometheus

[配置Nomad输出Prometheus数据很简单](https://www.nomadproject.io/guides/operations/monitoring-and-alerting/prometheus-metrics.html#step-1-enable-telemetry-on-nomad-servers-and-clients)
我们在[scripts目录下的nomad-client.sh](../scripts/nomad-client.sh#21)和[nomad-server.sh](../scripts/nomad-server.sh#17)都有一样的配置：
```text
telemetry {
  collection_interval = "1s"
  disable_hostname = true
  prometheus_metrics = true
  publish_allocation_metrics = true
  publish_node_metrics = true
}
```

### Prometheus Job的配置

参考[这里的教程](https://www.nomadproject.io/guides/operations/monitoring-and-alerting/prometheus-metrics.html#step-4-create-a-job-for-prometheus)，我们在[system-job/prometheus/job.hcl.tplt](prometheus/job.hcl.tplt#18)定义了prometheus配置，与教程的区别是我们添加了Consul的数据收集。

通过NameServer的内网ULB访问9090端口，就可以访问到Prometheus。
