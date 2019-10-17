## 阅读之前
本文档假设读者拥有一定的Terraform知识，在阅读之前，您应当熟悉以下知识：
[terrafor init](https://www.terraform.io/docs/commands/init.html)
[terraform apply](https://www.terraform.io/docs/commands/apply.html)
[terraform destroy](https://www.terraform.io/docs/commands/destroy.html)
[terraform taint](https://www.terraform.io/docs/commands/taint.html)
[terraform untaint](https://www.terraform.io/docs/commands/untaint.html)
[terraform workspace](https://www.terraform.io/docs/commands/workspace/index.html)
[terraform backend](https://www.terraform.io/docs/backends/index.html)
[terraform module](https://www.terraform.io/docs/modules/index.html)
[terraform state](https://www.terraform.io/docs/state/index.html)

您最好也拥有最基础的Docker知识，能够了解如何构造、启动容器，并与之互动。

## 部署模式

本项目有三种部署模式：
* test 单机测试部署一个集群，所有服务器都配有公网弹性IP，可以通过公网访问所有服务
* public 从KUN上部署一个公有云版本，Nomad Client可以访问公网，通过公网IP对外提供RocketMQ服务
* private 从KUN上在console.ucloudadmin.com环境部署一个内部使用版本，没有公网IP，暴露管理网可达内部IPV4地址提供RocketMQ服务

您可以在设置terraform代码的env_name的值来指定部署模式。private模式由于完全无法访问公网，所以还需要提前准备内网可达（ipv4/ipv6同时可达）的api代理服务与域名。

建议按照以下阅读顺序阅读实践

[Packer详解](/packer-scripts/readme.MD)
[Nomad集群网络简介](nomad.MD)
