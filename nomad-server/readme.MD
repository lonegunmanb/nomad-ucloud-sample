# Nomad集群中的Nomad Server

![](http://hashicorpfile.cn-bj.ufileos.com/nomad_public.jpg)

Nomad Server在Nomad集群中扮演了类似K8S控制面的角色，它负责整个集群的管理和调度。

一组Nomad Server可以有[3-7台服务器组成](https://www.nomadproject.io/guides/install/production/reference-architecture.html#ra)，推荐使用3台。

同样我们首先创建一个硬件隔离组。由于根目录下main.tf中我们把Nomad Server分为三个模块定义，所以硬件隔离组定义在根目录下的main.tf中。

同样由于Nomad Server分为三个模块定义，所以我们必须在根目录下的main.tf中声明属于Nomad Server的内网ULB以及listener，然后通过nomad_server_lb_id、nomad_server_lb_private_ip、nomad_server_4646_listener_id三个参数把外部创建好的资源id传入模块，在模块内部为每一台主机创建对应到listener的attachment。

Nomad Server模块其他的部分非常类似于Consul Server，所以在此不再赘述。
