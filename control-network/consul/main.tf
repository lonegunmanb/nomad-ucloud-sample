provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
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

locals {
  setup-script-path             = "${path.module}/setup.sh"
  reconfig-ssh-keys-script-path = "${path.module}/reconfig_ssh_keys.sh"
  reconfig-ssh-keys-script      = file(local.reconfig-ssh-keys-script-path)
}

data "template_file" "setup-script" {
  count    = local.instance_count
  template = file(local.setup-script-path)
  vars = {
    region             = var.region
    node-name          = ucloud_instance.consul_server[count.index].id
    consul-server-ip-0 = ucloud_instance.consul_server[0].private_ip
    consul-server-ip-1 = ucloud_instance.consul_server[1].private_ip
    consul-server-ip-2 = ucloud_instance.consul_server[2].private_ip
  }
}

resource "null_resource" "install_consul_server" {
  count = local.instance_count
  depends_on = [
    ucloud_instance.consul_server,
    ucloud_disk_attachment.consul_server_data,
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_instance.consul_server[count.index].private_ip
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      local.reconfig-ssh-keys-script,
    ]
  }
}

resource ucloud_lb consul_lb {
  name = "consulLb"
  internal = true
  tag = var.tag
  vpc_id = var.vpc_id
  subnet_id = var.subnet_id
}

resource ucloud_lb_listener consul_listener {
  load_balancer_id = ucloud_lb.consul_lb.id
  protocol = "tcp"
  listen_type = "request_proxy"
  name = "consul"
  port = 8500
}

resource ucloud_lb_attachment consul {
  count = local.instance_count
  listener_id = ucloud_lb_listener.consul_listener.id
  load_balancer_id = ucloud_lb.consul_lb.id
  resource_id = ucloud_instance.consul_server[count.index].id
  port = 8500
}

output consul_lb_ip {
  value = ucloud_lb.consul_lb.private_ip
}