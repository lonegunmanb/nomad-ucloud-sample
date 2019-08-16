provider "ucloud" {
  public_key = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id = var.project_id
  region = var.region
  base_url = var.ucloud_api_base_url
}

resource ucloud_vpc vpc {
  name = var.vpcName
  cidr_blocks = [var.cidr]
  tag = var.tag
}

resource ucloud_subnet subnet {
  name = var.subnetName
  cidr_block = var.cidr
  vpc_id = ucloud_vpc.vpc.id
  tag = var.tag
}

locals {
  controller_count = var.provision_from_kun ? 0 : var.controller_count
}

resource ucloud_security_group sg {
  count = local.controller_count
  name = "rktmq-control-temp-sg"
  rules {
    port_range = "22"
    protocol   = "tcp"
    cidr_block = var.allow_ip
    policy     = "accept"
  }
}

resource ucloud_instance controller {
  count = local.controller_count
  name              = "controller"
  tag               = var.tag
  availability_zone = var.az[0]
  image_id = var.controller_image_id
  instance_type = var.controler_instance_type
  vpc_id = ucloud_vpc.vpc.id
  subnet_id = ucloud_subnet.subnet.id
  root_password     = var.root_password
  charge_type       = var.charge_type
  security_group    = ucloud_security_group.sg.*.id[count.index]
  provisioner local-exec {
    command = "sleep 10"
  }
}

resource ucloud_disk dataDisk {
  count = local.controller_count
  availability_zone = var.az[0]
  disk_size = 100
  name = "controllerDisk-${count.index}"
  tag = var.tag
  charge_type = var.charge_type
}

resource ucloud_disk_attachment attachment {
  count = local.controller_count
  availability_zone = var.az[0]
  disk_id = ucloud_disk.dataDisk.*.id[count.index]
  instance_id = ucloud_instance.controller.*.id[count.index]
}

resource ucloud_eip controller_eip {
  count = local.controller_count
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type
  bandwidth     = 200
  name = "controller"
  tag           = var.tag
}

resource ucloud_eip_association association {
  count = local.controller_count
  eip_id = ucloud_eip.controller_eip.*.id[count.index]
  resource_id = ucloud_instance.controller.*.id[count.index]
}

data template_file mount_disk_script {
  template = file("./mount-disk.sh")
  vars = {
    project_root_dir = var.project_root_dir
  }
}

data template_file clone_project_script {
  template = file("./clone-tf-project.sh")
  vars = {
    terraform_project_url = var.terraform_project_url
    project_dir = "/project/${var.project_dir}"
    branch = var.git_branch
    project_dir = var.project_dir
    project_root_dir = var.project_root_dir
  }
}

resource null_resource setupController {
  depends_on = [ucloud_eip_association.association]
  count = local.controller_count
  provisioner remote-exec {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.controller_eip[count.index].public_ip
    }
    inline = [
      data.template_file.mount_disk_script.rendered,
      local.reconfig_ssh_keys_script,
    ]
  }
}

module consul_backend {
  source = "./consul-backend"
  az = var.az
  data_volume_size = var.consul_data_volume_size
  image_id = var.consul_image_id
  instance_type = var.consul_instance_type
  project_id = var.project_id
  region = var.region
  root_password = var.consul_root_password
  subnet_id = ucloud_subnet.subnet.id
  tag = var.tag
  ucloud_pub_key = var.ucloud_pub_key
  ucloud_secret = var.ucloud_secret
  vpc_id = ucloud_vpc.vpc.id
  ucloud_api_base_url = var.ucloud_api_base_url
}

locals {
  setup-consul-script-path = "${path.module}/setup-consul.sh"
}

data "template_file" "setup-script" {
  count    = length(var.az)
  template = file(local.setup-consul-script-path)
  vars = {
    region             = var.region
    node-name          = module.consul_backend.uhost_ids[count.index]
    consul-server-ip-0 = module.consul_backend.private_ips[0]
    consul-server-ip-1 = module.consul_backend.private_ips[1]
    consul-server-ip-2 = module.consul_backend.private_ips[2]
  }
}

data null_data_source consul_finish {
  inputs = {
    finishSignal = module.consul_backend.finishSignal
  }
}

module "backend_lb" {
  source = "../internal_lb"
  instance_ids = module.consul_backend.uhost_ids
  name = "consulLb-${var.tag}"
  ports = [8500]
  subnet_id = ucloud_subnet.subnet.id
  tag = var.tag
  vpc_id = ucloud_vpc.vpc.id
}

resource "null_resource" "install_consul_server_via_ipv4" {
  count = var.provision_from_kun ? 0 : length(module.consul_backend.private_ips)
  depends_on = [
    ucloud_eip_association.association,
    null_resource.setupController,
    data.null_data_source.consul_finish
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.consul_root_password
      host     = module.consul_backend.private_ips[count.index]
      bastion_host = ucloud_eip.controller_eip[0].public_ip
      bastion_user = "root"
      bastion_password = var.root_password
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      module.backend_lb.setup_loopback_script,
      local.reconfig_ssh_keys_script,
    ]
  }
}

module uhost_ipv6s {
  source = "../ipv6"
  disable = !var.provision_from_kun
  api_server_url = var.ipv6_api_url
  region_id = var.region_id
  resourceIds = module.consul_backend.uhost_ids
}

resource "null_resource" "install_consul_server_via_kun" {
  count = var.provision_from_kun ? length(module.consul_backend.private_ips) : 0
  depends_on = [
    ucloud_eip_association.association,
    null_resource.setupController,
    data.null_data_source.consul_finish
  ]
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.consul_root_password
      host     = module.uhost_ipv6s.ipv6s[count.index]
    }
    inline = [
      data.template_file.setup-script[count.index].rendered,
      module.backend_lb.setup_loopback_script,
      local.reconfig_ssh_keys_script,
    ]
  }
}

resource null_resource setupControllerBackendConfig {
  count = local.controller_count
  depends_on = [ucloud_eip_association.association]
  provisioner remote-exec {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.controller_eip[count.index].public_ip
    }
    inline = [
      "mkdir /config",
      "echo address = \"http://${module.backend_lb.lb_ip}:8500\" > /config/backend.tfvars"
    ]
  }
}

module consul_backend_lb_ipv6 {
  source = "../ipv6"
  disable = !var.provision_from_kun
  api_server_url = var.ipv6_api_url
  region_id = var.region_id
  resourceIds = list(module.backend_lb.lb_id)
}