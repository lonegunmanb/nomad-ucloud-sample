provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url = var.ucloud_api_base_url
}

resource ucloud_isolation_group isolation_group {
  name = "consul-backend-${var.tag}"
}

resource "ucloud_instance" "consul_server" {
  count             = local.instance_count
  name              = "consul-backend-${var.tag}-${count.index}"
  tag               = var.tag
  availability_zone = var.az[count.index % length(var.az)]
  image_id          = var.image_id
  instance_type     = var.instance_type
  root_password     = var.root_password
  charge_type       = var.charge_type
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  data_disk_size    = 0
  isolation_group   = ucloud_isolation_group.isolation_group.id
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "consul_data" {
  count             = local.instance_count
  availability_zone = var.az[count.index % length(var.az)]
  name              = "consul-backend-data-${var.tag}-${count.index}"
  disk_size         = var.data_volume_size
  tag               = var.tag
  charge_type = var.charge_type
}

resource "ucloud_disk_attachment" "consul_server_data" {
  count             = local.instance_count
  availability_zone = var.az[count.index % length(var.az)]
  disk_id           = ucloud_disk.consul_data[count.index].id
  instance_id       = ucloud_instance.consul_server[count.index].id
}