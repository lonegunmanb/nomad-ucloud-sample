provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
}

resource ucloud_lb consul_lb {
  name = "consulLb-${var.tag}"
  internal = true
  tag = var.tag
  vpc_id = var.vpc_id
  subnet_id = var.subnet_id
}

resource ucloud_lb_listener consul_listener {
  load_balancer_id = ucloud_lb.consul_lb.id
  protocol = "tcp"
  name = "consul"
  port = 8500
}

resource "ucloud_instance" "consul_server" {
  count             = local.instance_count
  name              = "consul-server-${count.index}"
  tag               = var.tag
  availability_zone = var.az[count.index % length(var.az)]
  image_id          = var.image_id
  instance_type     = var.instance_type
  root_password     = var.root_password
  charge_type       = var.charge_type
  vpc_id            = var.vpc_id
  subnet_id         = var.subnet_id
  provisioner "local-exec" {
    command = "sleep 10"
  }
}

resource "ucloud_disk" "consul_data" {
  count             = local.instance_count
  availability_zone = var.az[count.index % length(var.az)]
  name              = "consul-data-${count.index}"
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

resource ucloud_lb_attachment consul {
  count = local.instance_count
  listener_id = ucloud_lb_listener.consul_listener.id
  load_balancer_id = ucloud_lb.consul_lb.id
  resource_id = ucloud_instance.consul_server[count.index].id
  port = 8500
}