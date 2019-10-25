# BootStrap

如果我们想要部署一套Nomad集群，我们可以选择从自己的开发机上部署test模式；但如果要部署给公有云用户，我们面临这样几个问题：
* 需要一个一致的稳定的管理集群的环境
* 需要安全持久地存储产生的tfstate
* 不可在公网暴露控制面
* 同时管理多个租户的RocketMQ集群

为了减少运维成本以及提升效率，我们决定在KUN上构建控制器集群，该集群担负以下责任：
* 创建一组服务，用以充当Terraform Backend来存储tfstate
* 通过管理网创建Nomad集群，并连接初始化之
* 部署一组Deployment以及Service，处理公有云用户创建、销毁RocketMQ集群的请求，并查询RocketMQ访问地址
* 向管理网与办公网暴露集群控制面以及监控信号

我们在bootstrap目录下构建了另一组Terraform代码，用来在KUN上创建一组资源，并透过这组资源达成上述目标。

![](http://hashicorpfile.cn-bj.ufileos.com/backend%20%26%26%20kun.jpg)

## 需要持久化的数据
创建一个Nomad集群，有两种数据非常重要，不可以丢失。第一种就是产生的tfstate。

Terraform中[tfstate](https://www.terraform.io/docs/state/index.html)极其重要，State丢失或是被写坏，会导致Terraform再也无法管理相关资源。

还有就是创建集群所使用的参数文件。当然我们可以从tfstate文件来解析出集群当前的配置、规模等数据，但是由于tfstate是json格式的，并且tfstate含有资源所有的属性，所以还是妥善保存tfvars文件比较方便。

## 如何保存Backend

简单起见，我们通过使用之前用Packer构建的Consul镜像先搭建一个Consul集群，使用它的KV功能作为Backend。但是如何保存这个Consul集群的tfstate？如果我们在跳板机上创建这组Consul集群，那么tfstate就保留在跳板机的硬盘上，如果跳板机硬盘发生故障呢？

## Bootstrapper

所以我们决定，首先在KUN上创建一个[名为bootstrapper的Pod](main.tf#L139-L221)，并且申请一块[PVC](main.tf#L117-L133)挂载，把代码拷贝到PVC上，再由bootstrapper继续集群的创建工作，这样创建的Consul Backend tfstate就会保存在PVC上，它的持久性保障由PVC提供；Nomad集群和后续所有RocketMQ集群的tfstate就会保存在Consul Backend上，他们的持久性由3机Consul集群保障。

[bootstrap_script](main.tf#L26-L97)用template_file定义了bootstrapper启动后要执行的创建过程，模版的定义在[bootstrap.sh.tplt](bootstrap.sh.tplt)。
[destroy-script](main.tf#L99-L104)用template_file定义了销毁bootstrapper时如何销毁由bootstapper创建的资源的过程，模版的定义在[destroy.sh.tplt](destroy.sh.tplt)。

## bootstrap_script
bootstrap_script第一步是判断容器存储内是否含有代码目录，如果制作镜像时把代码做在了/code/${project_dir}下，那么我们就把镜像存储里的代码文件拷贝到pvc挂载的目录/project下，如果镜像本身不包含代码，那么就用执行git clone获取一份。
代码存储在PVC上，执行时产生的tfstate文件和后续渲染的tfvars参数文件都会保存在PVC上。

bootstrap_script后续先是分别写入参数文件（主要就是把在跳板机上创建KUN集群时参数文件的内容拷贝过来），然后分别创建网络、主机与System Job。

考虑到在bootstrap执行的过程中Pod就有可能因为意外重启，再次执行例如terraform workspace create等命令时会产生错误，所以每当一个步骤完成后，都会在当前目录下创建一个名为inited的文件；后续执行时如果看到这个文件，就跳过当前步骤。

## destroy-script
我们在跳板机上执行terraform destroy时，我们不只想销毁在KUN上创建的资源，更重要的是我们需要销毁由bootstrpper pod创建出来的所有资源。这个目标可以通过一个on destroy provisioner完成：
```hcl
resource "kubernetes_pod" "bootstraper" {
  depends_on = [
    kubernetes_config_map.bootstrap-script]
  metadata {
    name      = local.bootstraper_pod_name
    namespace = var.k8s_namespace
  }
  spec {
    container {
      name    = "bootstrap"
      image   = var.bootstrapper_image
      command = [
        "sh",
        "/bootstrap/bootstrap.sh"]
      ......
  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl -n ${var.k8s_namespace} exec ${local.bootstraper_pod_name} sh ${local.bootstrap_script_dir}/destroy.sh"
  }
}
```
一个when="destroy"的provisioner会在资源被删除前执行，当我们destroy到bootstrapper时，会首先通过跳板机执行kube exec这个bootstrapper pod上的destroy.sh脚本，通过该脚本，我们会把之前bootstrap_script里创建的System Job、Nomad集群、网络尽数销毁。

## Controller

Bootstapper Pod开始创建Nomad集群的同时，我们会创建名为controller的Deployment，它们就是用来处理用户网用户的请求，创建销毁RocketMQ集群的控制器。根据[Terraform使用环境变量读取配置项](https://www.terraform.io/docs/commands/environment-variables.html#tf_var_name)的原理，任意Terraform中定义的无默认值的变量，如果在参数文件与命令行中都没有定义，那么Terraform会尝试读取名为TF_VAR_${varname}的环境变量。在创建控制器的时候，我们会把Nomad集群的访问地址等相关信息，以环境变量的方式注入容器，这样控制器在执行Terraform操作时就无需再指明相关参数的值。

## Haproxy

main.tf的最后定义了名为haproxy的Deployment以及相应的Service。我们在用户网为Consul Server/Nomad Server以及NameServer都配置了内网ULB，而这些ULB从管理网无法直接访问；我们在KUN上创建了一些Haproxy Pod代理了这些内网ULB，并通过KUN Service暴露出去，这样管理网甚至办公网都可以访问到集群控制面。
