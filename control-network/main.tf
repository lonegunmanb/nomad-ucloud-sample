provider "ucloud" {
  public_key = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id = var.project_id
  region = var.region
}

resource ucloud_vpc vpc {
  name = var.vpcName
  cidr_blocks = [var.cidr]
  tag = "${var.tag}"
}

resource ucloud_subnet subnet {
  name = var.subnetName
  cidr_block = var.cidr
  vpc_id = ucloud_vpc.vpc.id
  tag = "${var.tag}"
}

resource ucloud_security_group sg {
  rules {
    port_range = "22"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }
}

resource ucloud_instance controller {
  count = local.instanceCount
  name              = "controller-${count.index}"
  tag               = var.tag
  availability_zone = var.az[count.index % length(var.az)]
  image_id = var.controller_image_id
  instance_type = var.controler_instance_type
  vpc_id = ucloud_vpc.vpc.id
  subnet_id = ucloud_subnet.subnet.id
  root_password     = var.root_password
  charge_type       = "dynamic"
  security_group    = ucloud_security_group.sg.id
  provisioner local-exec {
    command = "sleep 10"
  }
}

resource ucloud_disk dataDisk {
  count = local.instanceCount
  availability_zone = var.az[count.index % length(var.az)]
  disk_size = 100
  name = "controllerDisk-${count.index}"
  tag = var.tag
}

resource ucloud_disk_attachment attachment {
  count = local.instanceCount
  availability_zone = var.az[count.index % length(var.az)]
  disk_id = ucloud_disk.dataDisk.*.id[count.index]
  instance_id = ucloud_instance.controller.*.id[count.index]
}

resource ucloud_eip eip {
  count = local.instanceCount
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  name = "controller-${count.index}"
  tag           = var.tag
}

resource ucloud_eip_association association {
  count = local.instanceCount
  eip_id = ucloud_eip.eip.*.id[count.index]
  resource_id = ucloud_instance.controller.*.id[count.index]
}

resource ucloud_lb controllerLb {
  name = "controllerLb"
  tag = var.tag
  vpc_id = ucloud_vpc.vpc.id
  subnet_id = ucloud_subnet.subnet.id
}

resource ucloud_eip lbEip {
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = "dynamic"
  bandwidth     = 200
  name = "controllerLb"
  tag           = var.tag
}

resource ucloud_eip_association lb {
  eip_id = ucloud_eip.lbEip.id
  resource_id = ucloud_lb.controllerLb.id
}

resource ucloud_lb_listener ssh {
  load_balancer_id = ucloud_lb.controllerLb.id
  protocol = "tcp"
  listen_type = "request_proxy"
  port = "22"
}

resource ucloud_lb_attachment ssh {
  count = local.instanceCount
  listener_id = ucloud_lb_listener.ssh.id
  load_balancer_id = ucloud_lb.controllerLb.id
  resource_id = ucloud_instance.controller.*.id[count.index]
  port = "22"
}

locals {
  reconfig_ssh_keys_script = file("./reconfig_ssh_keys.sh")
}

resource null_resource setupScript {
  depends_on = [ucloud_lb_attachment.ssh]
  count = local.instanceCount
  provisioner remote-exec {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.eip[count.index].public_ip
    }
    inline = [
      local.reconfig_ssh_keys_script,
    ]
  }
}

data template_file provision-consul-backends {
  template = file("./provision-consul-backends.sh")
  vars {
    terraform_project_url = var.terraform_project_url
    project_dir = var.project_dir
    region = var.region
    az = "[${join(",", var.az)}]"
    root_password = var.consul_root_password
    tag = var.tag
    vpc_id = ucloud_vpc.vpc.id
    subnet_id = ucloud_subnet.subnet.id
    data_volume_size = var.consul_data_volume_size
    image_id = var.consul_image_id
    instance_type = var.consul_instance_type
  }
}

output vpcId {
  value = ucloud_vpc.vpc.id
}

output lbIp {
  value = ucloud_eip.lbEip.public_ip
}

output controlerIps {
  value = ucloud_eip.eip.*.public_ip
}