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
  charge_type       = var.charge_type
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
  charge_type = var.charge_type
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
  charge_type   = var.charge_type
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

resource ucloud_eip controlerLbEip {
  internet_type = "bgp"
  charge_mode   = "traffic"
  charge_type   = var.charge_type
  bandwidth     = 200
  name = "controllerLb"
  tag           = var.tag
}

resource ucloud_eip_association lb {
  eip_id = ucloud_eip.controlerLbEip.id
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
  }
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
      data.template_file.mount_disk_script.rendered,
      data.template_file.clone_project_script.rendered,
      file("./reconfig_ssh_keys.sh"),
    ]
  }
}

data template_file provision_consul_backends_script {
  template = file("./provision-consul-backends.sh")
  vars = {
    project_id = var.project_id
    ucloud_pub_key = var.ucloud_pub_key
    ucloud_secret = var.ucloud_secret
    project_dir = "/project/${var.project_dir}"
    region = var.region
    az = "[${join(",", formatlist("\"%s\"", var.az))}]"
    root_password = var.consul_root_password
    tag = var.tag
    vpc_id = ucloud_vpc.vpc.id
    subnet_id = ucloud_subnet.subnet.id
    data_volume_size = var.consul_data_volume_size
    image_id = var.consul_image_id
    instance_type = var.consul_instance_type
    charge_type = var.charge_type
  }
}

data template_file destroy_consul_backends_script {
  template = file("./destroy-consul-backends.sh")
  vars = {
    project_dir = "/project/${var.project_dir}"
  }
}

resource null_resource provision_consul_backend {
  depends_on = [null_resource.setupScript, ucloud_eip_association.association, ucloud_disk_attachment.attachment, ucloud_security_group.sg]
  provisioner remote-exec {
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.eip[0].public_ip
    }
    inline = [
      data.template_file.provision_consul_backends_script.rendered
    ]
  }
  provisioner remote-exec {
    when = "destroy"
    connection {
      type     = "ssh"
      user     = "root"
      password = var.root_password
      host     = ucloud_eip.eip[0].public_ip
    }
    inline = [
      data.template_file.destroy_consul_backends_script.rendered
    ]
  }
}

data ucloud_lbs consul_lb {
  depends_on = [null_resource.provision_consul_backend]
  vpc_id = ucloud_vpc.vpc.id
  subnet_id = ucloud_subnet.subnet.id
  name_regex = "consulLb"
}

resource null_resource set_consul_lb_url {
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
      "echo export TF_VAR_consul_backend=${data.ucloud_lbs.consul_lb.lbs.0.private_ip} >> ~/.bashrc"
    ]
  }
}