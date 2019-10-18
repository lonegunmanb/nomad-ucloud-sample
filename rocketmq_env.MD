# test/public/private下RocketMQ提供服务的方式

本项目提供的是一个多租户RocketMQ集群，public模式的用户是UCloud公有云的其他用户，private模式的用户是公司内部同事。

## public模式

由于多租户的特性，我们无法控制使用RocketMQ的用户他们的VPC网段划分，而目前UCloud公有云VPC Cidr的保留段控制实际上只是一个GUI上的限制，对API调用没有做限制，这就导致无论我们给Nomad集群设置怎么样的Cidr，都有可能会遇到与用户VPC Cidr冲突的情况，所以通过与用户VPC打通来提供内网IP给用户访问的方式是行不通的。所以我们决定，通过公网弹性IP向用户暴露服务。由于时间仓促，我们还没有完成对磁盘IOPS以及磁盘占用空间的限制，所以通过公网IP对外提供服务，我们还可以通过限制弹性IP带宽简单地实现对这两项指标的限制。

rocketmq-job-namesvr/main.tf中我们声明了一个公网ULB，并且把ULB ID传入rocketmq-job-namesvr-namesvr-namesvr-job.hcl；启动RocketMQ容器的同时，我们会启动一个带有terraform运行时环境的容器，并且动态渲染一个terraform代码文件，执行后会把容器所在的宿主机IP以及获得的动态端口号添加到ULB后端，这样我们就可以对外暴露一个稳定的公网IP和端口；即使容器发生了漂移，在新的宿主机上启动后，也会再次执行同样的terraform代码，而terraform的幂等性保障了无论是在同一台宿主机上被反复启动，还是随着漂移在不同的机器上被启动，始终只会保证ULB后端对接了NameServer当前的服务地址。

## private模式

private模式意在管理网部署一个与public模式一样的多租户RocketMQ集群，但管理网不允许使用公网IP，所以我们必须寻找其他方法。

目前private模式是部署在console.ucloudadmin.com环境中，该环境提供了一个与UCloud公有云几乎一样的环境，该环境主机的内网IP是管理网可达的。由于Broker的信息是注册到NameServer上的，所以问题的关键就变成了如何让管理网用户能够访问到NameServer容器。

RocketMQ提供了一种基于HTTP Endpoint的访问NameServer的[方式](https://rocketmq.apache.org/docs/best-practice-namesvr/)，简单来说，RocketMQ Java SDK在穷尽所有方法都找不到NameServer配置的情况下，默认会通过http get访问http://jmenv.tbsite.net:8080/rocketmq/nsaddr 这个地址，如果该地址能够返回一组合法的NameServer服务地址，那么Java SDK就会使用这组地址，并且每2分钟重新访问一次，确保自己保存的NameServer地址是最新的。这种方式同时也是RocketMQ官方推荐在生产环境使用的方式。在这个url中，jmenv.tbsite.net和nsaddr这两部分是可以通过rocketmq.namesrv.domain和rocketmq.namesrv.domain.subgroup这两个Java配置项设置的，启动Java进程前指定JAVA_OPT，就可以设置这两个配置项。

现在的问题就变成了如何提供一个HTTP服务，对外已http://${domain}:8080/rocketmq/${nameserver_address}的形式发布NameServer地址。

我们之前提到过，为了能够组网，我们使用了Consul Connect作为Service Mesh方案，所以无论是NameServer还是Broker，都会在Consul上注册一个对应的服务，注册信息有容器运行的宿主机IP，以及使用的端口号。如何把这些信息通过HTTP暴露出来呢？我们可以构造一段很简单的go代码，侦听http请求，并返回一个静态字符串，这个静态字符串，是我们在启动任务时，通过consul_template渲染出来的，我们可以看一下rocketmq-job-namesvr/namesvr/namesvr-job.hcl中相关代码段：
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
代码中的Fprintf里的部分，就是一段consul_template模版代码，查询Consul中NameServer的信息，拼接成一个静态字符串。

我们启动的任务，就是在容器中利用go run命令编译执行这段代码，如果我们这时用http get访问这个容器的8080端口，就可以得到对应的NameServer地址，并且consul_template+nomad的搭配会确保，如果它所依赖的Consul服务注册信息发生了变化，比如某个NameServer容器发生了漂移，那么Nomad会重新渲染这段代码，并且重启这个容器，确保我们总是能够得到最新的NameServer地址。

但是这个容器本身也面临和NameServer一样的问题，它也只能是使用宿主机IP，并对外暴露一个动态端口，如何能够给用户提供一个稳定的url？

我们在这里使用了[fabio](https://github.com/fabiolb/fabio)，这是一个搭配Consul工作的云原声http(s)/tcp负载均衡器。我们只要把执行go run的容器本身也在Consul上注册一个服务，并且附上一个特定的[tag](rocketmq-job-namesvr/namesvr/namesvr-job.hcl#L29)，fabio就会添加一条路由记录。例如，如果我们注册服务时附加的tag是：
```text
urlprefix-/foo
```

那么我们可以通过访问http://${url_to_fabio_svc}/foo 这个地址来访问这个服务。通过这种方式，用户只要能访问fabio容器，附上正确的路径，就可以被中转到go run容器上。用户如何访问fabio容器呢？

我们在这里使用了[Nomad System Job](https://www.nomadproject.io/docs/schedulers.html), 一个System类型的Job类似K8S的DaemonSet，Nomad会在每一个符合Job中定义的约束的Client节点上启动相同的Job。我们在system-job目录下定义了这样的System Job，会在所有的NameServer类型宿主机上都启动一个fabio容器，并且侦听8080端口，同时我们在创建Nomad集群时，申请了一个内网ULB，把所有的NameServer宿主机都添加到后端，这样通过访问这个内网ULB，我们就可以触达fabio容器，进而访问到对应的go run容器。

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
