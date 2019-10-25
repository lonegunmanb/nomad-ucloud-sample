## 阅读之前
在阅读之前，您应当熟悉以下Terraform知识：
* [terrafor init](https://www.terraform.io/docs/commands/init.html)
* [terraform apply](https://www.terraform.io/docs/commands/apply.html)
* [terraform destroy](https://www.terraform.io/docs/commands/destroy.html)
* [terraform taint](https://www.terraform.io/docs/commands/taint.html)
* [terraform untaint](https://www.terraform.io/docs/commands/untaint.html)
* [terraform workspace](https://www.terraform.io/docs/commands/workspace/index.html)
* [terraform backend](https://www.terraform.io/docs/backends/index.html)
* [terraform module](https://www.terraform.io/docs/modules/index.html)
* [terraform state](https://www.terraform.io/docs/state/index.html)

您最好了解以下Consul知识（或者可以在随后的阅读中根据需要去了解）：
* [consul glossary](https://www.consul.io/docs/glossary.html)
* [consul connect](https://www.consul.io/docs/connect/index.html)
* [consul connect on nomad](https://www.consul.io/docs/connect/platform/nomad.html)

您最好了解以下Nomad知识（或者可以在随后的阅读中根据需要去了解）：
* [nomad](https://www.nomadproject.io/guides/install/production/reference-architecture.html)
* [nomad scheduler](https://www.nomadproject.io/docs/schedulers.html)

我们大量使用了Consul Template，这是一个结合go模版功能，可以把来自Consul的信息渲染到预设模版中，实现动态服务发现的工具，结合Nomad Template，可以发挥强大的功能：
* [consul template](https://github.com/hashicorp/consul-template)
* [nomad template](https://www.nomadproject.io/docs/job-specification/template.html)

## 部署模式

本项目有三种部署模式：
* test 单机测试部署一个集群，所有服务器都配有公网弹性IP，可以通过公网访问所有服务
* public 从KUN上部署一个公有云版本，Nomad Client可以访问公网，通过公网IP对外提供RocketMQ服务
* private 从KUN上在console.ucloudadmin.com环境部署一个内部使用版本，没有公网IP，暴露管理网可达内部IPV4地址提供RocketMQ服务

您可以在设置terraform代码的env_name的值来指定部署模式。private模式由于完全无法访问公网，所以还需要提前准备内网可达（ipv4/ipv6同时可达）的api代理服务与域名。

建议按照以下阅读顺序阅读实践

* [项目结构](dirs.MD)
* [Packer详解](/packer-scripts/readme.MD)
* [Nomad集群网络简介](nomad.MD)
* [构建test模式Nomad集群](provision_test.MD)
* [consul-server](consul-server/readme.MD)
* [nomad-server](nomad-server/readme.MD)
* [nomad-client](nomad-client/readme.MD)
* [滚动更新](rolling-update/readme.MD)
* [test与public模式下的RocketMQ](rocketmq.MD)
* [test/public/private下RocketMQ提供服务的方式](rocketmq_env.MD)
* [system-job](system-job/readme.MD)
* [bootstrapper](bootstrap/readme.MD)
