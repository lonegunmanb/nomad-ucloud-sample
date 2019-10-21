# 项目
本节简单介绍各文件夹功能：
* bootstrap：创建KUN上控制器集群，以及在用户网创建一套Nomad集群
* consul-server: 用户网Consul集群模块
* control-network：类似用户网Consul集群，在用户网创建一组独立的Consul集群，用以给KUN上的控制器做backend
* internal_lb： 在用户网创建一个内网ULB及相应的添加loopback网卡脚本的Terraform模块
* ipv6： 通过python把用户网内网IPV4转为KUN上IPV6的Terraform模块
* module_variables： 用奇技淫巧解决两个Terraform[模块间删除资源时产生的环依赖](https://mp.weixin.qq.com/s?__biz=MzI3Mzg4NTAxMw==&mid=2247483900&idx=1&sn=e378949c078c86c51e919d31a7264ea2)的模块
* network： 创建（或者复用）Nomad集群VPC的Terraform模块
* nomad-client： Nomad集群Client模块
* nomad-server： Nomad集群Server某块
* packer-scripts： Packer构建脚本
* rocketmq-job-broker： 在Nomad集群上创建RocketMQ Broker的模块
* rocketmq-job-namesvr： 在Nomad集群上创建RocketMQ NameServer的模块
* rolling-update： 滚动更新Nomad集群的工具脚本
* scripts： packer或者terraform初始化主机时执行的shell脚本
* system-job： 创建Nomad集群后创建的一些Nomad System Job

创建Nomad集群的Terraform代码在项目根目录下
