mkdir /plugin
cd /plugin
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-consul_v${TF_PLUGIN_CONSUL_VERSION}_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-null_v${TF_PLUGIN_NULL_VERSION}_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-template_v${TF_PLUGIN_TEMPLATE_VERSION}_x4
wget -nv http://hashicorpfile.cn-bj.ufileos.com/terraform-provider-ucloud_v${TF_PLUGIN_UCLOUD_VERSION}_x4
chmod +x terraform-provider-consul_v${TF_PLUGIN_CONSUL_VERSION}_x4
chmod +x terraform-provider-null_v${TF_PLUGIN_NULL_VERSION}_x4
chmod +x terraform-provider-template_v${TF_PLUGIN_TEMPLATE_VERSION}_x4
chmod +x terraform-provider-ucloud_v${TF_PLUGIN_UCLOUD_VERSION}_x4
sync