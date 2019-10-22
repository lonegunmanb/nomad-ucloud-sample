# Nomad集群中的Nomad Client

![](http://hashicorpfile.cn-bj.ufileos.com/nomad_public.jpg)

Nomad Client类似K8S中的Node，RocketMQ所有的容器都运行在这些Client主机上。

nomad-client/variables.tf中的class变量代表Nomad Client的类别，由于RocketMQ本身的设计，Broker类型的容器需要挂载高性能大容量磁盘，而NameServer则不需要；所以我们用class把Client主机分成两类，给broker类型主机分配更多的内存，更大更好的磁盘。

在根目录下main.tf中，我们首先把client按照class分成两组，每组又各自分成3个模块定义，这样一共6组Nomad Client模块定义了所有的Client机器。

Nomad Client不需要知道Nomad Server的IP，它们只需要知道集群Consul Server的IP，发现Nomad Server的工作通过Consul的服务发现就可以完成。

我们在Nomad Client模块定义中也定义了硬件隔离组：
```hcl
resource "ucloud_isolation_group" "nomad_clients_isolation_group" {
  count = floor((var.instance_count - 1) / 7) + 1
  name = "${var.class}-${var.group}-${count.index}"
}
```

因为单个Nomad Client模块中的所有资源都在同一个可用区内，而一个硬件隔离组在一个可用区内至多可以添加7台主机，所以我们根据主机数量计算所需要的硬件隔离组数量，确保每7台主机组成一个硬件隔离组。由于所有机器都被纳入硬件隔离组的管理，所以无论机器规模多大，单一硬件故障至多影响到集群整体的1/7的机器。

nomad-client/main.tf中定义的nomad_clients，有一个特别的lifecycle定义：
```hcl
resource "ucloud_instance" "nomad_clients" {
  count             = var.instance_count
  name              = "nomad-client-${var.class}-${var.group}-${count.index}"
  tag               = var.cluster_id
  availability_zone = var.az
  image_id          = var.image_id
  instance_type     = var.instance_type
  root_password     = var.root_password
  charge_type       = var.charge_type
  duration          = var.duration
  security_group    = var.sg_id
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  boot_disk_type    = var.use_udisk ? (var.udisk_type == "rssd_data_disk" ? "cloud_ssd" : "local_ssd") : var.local_disk_type
  data_disk_type    = var.local_disk_type
  data_disk_size    = var.use_udisk ? 0 : var.data_volume_size
  remark            = var.az
  isolation_group   = ucloud_isolation_group.nomad_clients_isolation_group.*.id[floor(count.index / 7)]
  provisioner "local-exec" {
    command = "sleep 10"
  }
  lifecycle {
    create_before_destroy = true
  }
}
```
这个create_before_destroy的lifecycle定义，会确保我们如果要对uhost进行"删除-重建"式的更新时（主要是更换镜像），会先创建新主机，然后删除老主机，这样可以尽可能减少容器不可用的时间。
