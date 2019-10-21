mkdir /plugin
cd /plugin
wget -nv ${FILE_SERVER}/terraform-provider-consul_v${TF_PLUGIN_CONSUL_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-nomad_v${TF_PLUGIN_NOMAD_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-null_v${TF_PLUGIN_NULL_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-template_v${TF_PLUGIN_TEMPLATE_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-ucloud_v${TF_PLUGIN_UCLOUD_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-external_v${TF_PLUGIN_EXTERNAL_VERSION}_x4
wget -nv ${FILE_SERVER}/terraform-provider-local_v${TF_PLUGIN_LOCAL_VERSION}_x4
chmod +x terraform-provider-consul_v${TF_PLUGIN_CONSUL_VERSION}_x4
chmod +x terraform-provider-nomad_v${TF_PLUGIN_NOMAD_VERSION}_x4
chmod +x terraform-provider-null_v${TF_PLUGIN_NULL_VERSION}_x4
chmod +x terraform-provider-template_v${TF_PLUGIN_TEMPLATE_VERSION}_x4
chmod +x terraform-provider-ucloud_v${TF_PLUGIN_UCLOUD_VERSION}_x4
chmod +x terraform-provider-external_v${TF_PLUGIN_EXTERNAL_VERSION}_x4
chmod +x terraform-provider-local_v${TF_PLUGIN_LOCAL_VERSION}_x4
