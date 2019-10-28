# test/public/private下RocketMQ提供服务的方式

本项目提供的是一个多租户RocketMQ集群，public模式的用户是UCloud公有云的其他用户，private模式的用户是公司内部同事。

## public模式

由于多租户的特性，我们无法控制使用RocketMQ的用户他们的VPC网段划分，而目前UCloud公有云VPC Cidr的保留段控制实际上只是一个GUI上的限制，对API调用没有做限制，这就导致无论我们给Nomad集群设置怎么样的Cidr，都有可能会遇到与用户VPC Cidr冲突的情况，所以通过与用户VPC打通来提供内网IP给用户访问的方式是行不通的。所以我们决定，通过公网弹性IP向用户暴露服务。由于时间仓促，我们还没有完成对磁盘IOPS以及磁盘占用空间的限制，所以通过公网IP对外提供服务，我们还可以通过限制弹性IP带宽简单地实现对这两项指标的限制。

rocketmq-job-namesvr/main.tf中我们声明了一个公网ULB，并且把ULB ID传入rocketmq-job-namesvr-namesvr-namesvr-job.hcl；启动RocketMQ容器的同时，我们会启动一个带有terraform运行时环境的容器，并且动态渲染一个terraform代码文件，执行后会把容器所在的宿主机IP以及获得的动态端口号添加到ULB后端，这样我们就可以对外暴露一个稳定的公网IP和端口；即使容器发生了漂移，在新的宿主机上启动后，也会再次执行同样的terraform代码，而terraform的幂等性保障了无论是在同一台宿主机上被反复启动，还是随着漂移在不同的机器上被启动，始终只会保证ULB后端对接了NameServer当前的服务地址。

public模式下的broker无论是向NameServer注册自己，还是对外暴露服务，使用的都是一个[公网弹性IP](rocketmq-job-broker/main.tf#L13)（实际上申请了3个，每个Broker一个），通过[Nomad任务定义中的template](rocketmq-job-broker/broker-job.hcl.tplt#84)将公网弹性IP渲染到Broker的配置文件中。为了使得consul_template渲染时可以读取到这个弹性IP，我们在提交这个Nomad任务之前，先申请好IP，并且在集群的Consul上[以Key/Value的形式记录了IP的值](rocketmq-job-broker/main.tf#L37-L53)：
```hcl
resource "consul_keys" "eip_public_ip" {
  count = var.internal_use ? 0 : 3
  key {
    path   = "brokerEip/${local.broker_clusterId}/eip/${count.index}"
    value  = ucloud_eip.broker_eip.*.public_ip[count.index]
    delete = true
  }
}

resource "consul_keys" "eip_id" {
  count = var.internal_use ? 0 : 3
  key {
    path   = "brokerEip/${local.broker_clusterId}/eipId/${count.index}"
    value  = ucloud_eip.broker_eip.*.id[count.index]
    delete = true
  }
}
```

注意这里的delete要显式设置为true，否则在删除集群时不会连带删除Consul中的KV信息。

申请好的弹性IP通过渲染配置文件的方式被渲染进了Broker的配置文件，接下来要把这个弹性IP[绑定到容器所在的宿主机](rocketmq-job-broker/broker-job.hcl.tplt#154-#183)：
```hcl
template {
        data = <<EOF
            variable ucloud_pub_key {}
            variable ucloud_secret {}
            variable project_id {}
            variable region {}
            variable ucloud_api_base_url {}

            terraform {
              backend "consul" {
                address = "{{with service "consul"}}{{with index . 0}}{{.Address}}:8500{{end}}{{end}}"
                scheme = "http"
                path = "brokerEip/${cluster-id}/eip_association/{{ env "NOMAD_ALLOC_INDEX" }}"
              }
            }

            provider "ucloud" {
              public_key = var.ucloud_pub_key
              private_key = var.ucloud_secret
              project_id = var.project_id
              region = var.region
              base_url = var.ucloud_api_base_url
            }

            resource "ucloud_eip_association" "association-{{ env "NOMAD_ALLOC_INDEX" }}" {
              count = ${eip-count}
              {{$allocId := env "NOMAD_ALLOC_INDEX"}}
              eip_id      = "{{key (printf "brokerEip/${cluster-id}/eipId/%s" $allocId)}}"
              resource_id = "{{env "node.unique.name"}}"
            }
            EOF
        destination = "local/tf/main.tf"
        change_mode = "noop"
      }
```
我们实际上做的就是，在启动Broker容器的同时，在同一台宿主机上启动一个含有Terraform运行时环境的容器，同样通过consul_template渲染一个Terraform代码文件，把通过Consul KV读取到的弹性IP信息渲染进去，然后执行，这个Terraform容器就会把分配到的弹性IP绑定到宿主机上。即使Broker发生了漂移，在新的宿主机上启动后，这个伴生的Terraform仍然会把同一个弹性IP绑定到新的宿主机上。所以Broker暴露的端口在容器漂移后会发生改变，而绑定的公网IP则不会。

## Terraform运行时环境镜像

我们在[rocketmq-job-namesvr/terraform-dockerfile/Dockerfile](rocketmq-job-namesvr/terraform-dockerfile/Dockerfile)中定义了这个含有Terraform运行时环境的镜像，值得注意的是，我们在代码的最后有这样一行：
```dockerfile
&& echo plugin_cache_dir = \"/plugin\" >> ~/.terraformrc
```
在这里我们设置了[plugin_cache_dir](https://www.terraform.io/docs/configuration/providers.html#provider-plugin-cache)，因为Terraform运行时会通过公网下载所需要的Terraform插件，而我们的部署环境很可能是无法连接公网的，所以我们在通过Packer构建Nomad Client镜像时，就把所需要的Terraform插件都下载到/plugin目录下，启动Terraform容器时，我们把宿主机的/plugin挂载到容器的/plugin目录下，并且在构建容器镜像时就指定使用该目录作为plugin_cache_dir，这样就可以完全脱离公网工作。

构建这个镜像很简单，只需要传入对应的VERSION参数指定Terraform版本即可。

## private模式

private模式意在管理网部署一个与public模式一样的多租户RocketMQ集群，但管理网不允许使用公网IP，所以我们必须寻找其他方法。

目前private模式是部署在console.ucloudadmin.com环境中，该环境提供了一个与UCloud公有云几乎一样的环境，该环境主机的内网IP是管理网可达的。由于Broker的信息是注册到NameServer上的，所以问题的关键就变成了如何让管理网用户能够访问到NameServer容器。

RocketMQ提供了一种基于HTTP Endpoint的访问NameServer的[方式](https://rocketmq.apache.org/docs/best-practice-namesvr/)，简单来说，RocketMQ Java SDK在穷尽所有方法都找不到NameServer配置的情况下，默认会通过http get访问http://jmenv.tbsite.net:8080/rocketmq/nsaddr 这个地址，如果该地址能够返回一组合法的NameServer服务地址，那么Java SDK就会使用这组地址，并且每2分钟重新访问一次，确保自己保存的NameServer地址是最新的。这种方式同时也是RocketMQ官方推荐在生产环境使用的方式。在这个url中，jmenv.tbsite.net和nsaddr这两部分是可以通过rocketmq.namesrv.domain和rocketmq.namesrv.domain.subgroup这两个Java配置项设置的，启动Java进程前指定JAVA_OPT，就可以设置这两个配置项。

现在的问题就变成了如何提供一个HTTP服务，对外已http://${domain}:8080/rocketmq/${nameserver_address}的形式发布NameServer地址。

我们之前提到过，为了能够组网，我们使用了Consul Connect作为Service Mesh方案，所以无论是NameServer还是Broker，都会在Consul上注册一个对应的服务，注册信息有容器运行的宿主机IP，以及使用的端口号。如何把这些信息通过HTTP暴露出来呢？我们可以构造一段很简单的go代码，侦听http请求，并返回一个静态字符串，这个静态字符串，是我们在启动任务时，通过consul_template渲染出来的，我们可以看一下rocketmq-job-namesvr/namesvr/namesvr-job.hcl中[相关代码段](rocketmq-job-namesvr/namesvr/namesvr-job.hcl#L39-L51)：
```go
package main
import (
"fmt"
"log"
"net/http"
)
func myHandler(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "{{range $i, $svc := service "nameServer${cluster-id}"}}{{if ne $i 0}};{{end}}{{ $svc.Address }}:{{ $svc.Port }}{{end}}")
}
func main(){
	http.HandleFunc("/", myHandler)
	log.Fatal(http.ListenAndServe(":8080", nil))
}
```
代码中的Fprintf里的部分，就是一段consul_template模版代码，查询Consul中NameServer的信息(我们的name server都会在consul上注册一个名为nameServer${cluster-id}的服务，在模版里用$svc := service "nameServer${cluster-id}"就可以查询出服务可用终结点的ip和端口)，拼接成一个静态字符串。

我们启动的任务，就是在容器中利用go run命令编译执行这段代码，如果我们这时用http get访问这个容器的8080端口，就可以得到对应的NameServer地址，并且consul_template+nomad的搭配会确保，如果它所依赖的Consul服务注册信息发生了变化，比如某个NameServer容器发生了漂移，那么Nomad会重新渲染这段代码，并且重启这个容器，确保我们总是能够得到最新的NameServer地址。

但是这个容器本身也面临和NameServer一样的问题，它也只能是使用宿主机IP，并对外暴露一个动态端口，如何能够给用户提供一个稳定的url？

## 基于Service Tag的Fabio转发

我们在这里使用了[fabio](https://github.com/fabiolb/fabio)，这是一个搭配Consul工作的云原生http(s)/tcp负载均衡器。我们只要把执行go run的容器本身也在Consul上注册一个服务，并且附上一个特定的[tag](rocketmq-job-namesvr/namesvr/namesvr-job.hcl#L29)，fabio就会添加一条路由记录。例如，如果我们注册服务时附加的tag是：
```text
urlprefix-/foo
```

那么我们可以通过访问http://${fabio_svc}/foo 这个地址来访问这个服务。通过这种方式，用户只要能访问fabio容器，附上正确的路径，就可以被中转到go run容器上。
```hcl
service {
   name = "nameSvrIndex-${cluster-id}"
   port = "tcp"
   tags = ["urlprefix-/rocketmq/${cluster-id}"]
   check {
     type = "tcp"
     port = "tcp"
     interval = "10s"
     timeout = "2s"
   }
}
```
注意，这里的check必不可少，fabio为了要自动摘除不健康的后端，所以只会把请求路由给健康检查正常的服务。

用户如何访问fabio容器呢？

我们在这里使用了[Nomad System Job](https://www.nomadproject.io/docs/schedulers.html#system), 一个System类型的Job类似K8S的DaemonSet，Nomad会在每一个符合Job中定义的约束的Client节点上启动相同的Job。我们在system-job目录下定义了这样的System Job，会在所有的NameServer类型宿主机上都启动一个fabio容器，并且侦听8080端口，同时我们在创建Nomad集群时，申请了一个内网ULB，把所有的NameServer宿主机都添加到后端，这样通过访问这个内网ULB，我们就可以触达fabio容器，进而访问到对应的go run容器。

![](http://hashicorpfile.cn-bj.ufileos.com/fabio.jpg)

要使用这种方式，在创建完Nomad集群后，我们还需要跳转到system-job目录下创建System Job，我们给出一个配置文件作为参考：
```json
{
  "fabio_image": "uhub.service.ucloud.cn/lonegunmanb/fabio",
  "prometheus_image": "uhub.service.ucloud.cn/lonegunmanb/prometheus",
  "namesvr_fabio_port": 8080,
  "prometheus_port": 9090,
  "nomad_cluster_id": "roger",
  "remote_state_backend_url": "http://localhost:8500"
}
```
创建的过程与之前一样，也是执行terraform init后apply，本文不再赘述。

我们在System Job中除了定义了fabio任务以外，还定义了一个prometheus服务，它通过Consul发现了所有Nomad Server以及Nomad Client节点，然后收集Nomad集群的各项metric并以prometheus的标准输出，本文不再赘述。

## 小结
简单小结一下，test与public模式下，一个公网ULB通过9876端口向用户提供了3个Broker的公网EIP和对应的宿主机端口号，而在private模式下，用户通过http get，透过统一的内网ULB -> NameServer宿主机上的fabio容器 -> go run运行的NameServer索引服务，获取了3台NameServer的内网IP与宿主机端口，进而获取3台Broker的内网IP与宿主机端口。

另外private部署模式的这种HTTP Endpoint方式，经过验证Java SDK是[直接支持](https://rocketmq.apache.org/docs/best-practice-namesvr/)的，而Golang的[Native SDK](https://github.com/apache/rocketmq-client-go/tree/native)是不支持的，但是我们可以自己通过一个独立的goroutine轮询HTTP Endpoint来实现这个功能。
