locals {
  nomad_server_ip = length(data.terraform_remote_state.nomad.outputs.nomad_server_ip) > 15 ? "[${data.terraform_remote_state.nomad.outputs.nomad_server_ip}]":data.terraform_remote_state.nomad.outputs.nomad_server_ip
}

provider "ucloud" {
  public_key  = var.ucloud_pubkey
  private_key = var.ucloud_secret
  project_id  = local.projectId
  region      = local.region
  base_url    = var.ucloud_api_base_url
}

resource "ucloud_eip" "broker_eip" {
  count = 3
  internet_type = "bgp"
  name = "broker-${local.broker_clusterId}-${count.index}"
  charge_mode = "traffic"
  charge_type = "dynamic"
  tag = var.nomad_cluster_id
  bandwidth = var.broker_size * var.base_bandwidth
}
//because we create ucloud_eip_association inside nomad job, so before we destroy eip, we must unbind eip first, by ucloud cli
resource "null_resource" "eip_destroy_helper" {
  count = 3
  depends_on = [ucloud_eip.broker_eip]
  provisioner "local-exec" {
    when = "destroy"
    command = "ucloud config --profile=default --active=true --region=${local.region} --base-url=${var.ucloud_api_base_url} --public-key=${var.ucloud_pubkey} --private-key=${var.ucloud_secret} && ucloud eip unbind --eip-id=${ucloud_eip.broker_eip.*.id[count.index]} --region=${local.region} --project-id=${local.projectId} --public-key=${var.ucloud_pubkey} --private-key=${var.ucloud_secret}"
  }
}

provider "consul" {
  address = local.consul_access_url
  datacenter = local.region
}

resource "consul_keys" "eip_public_ip" {
  count = 3
  key {
    path = "brokerEip/${local.broker_clusterId}/eip/${count.index}"
    value = ucloud_eip.broker_eip.*.public_ip[count.index]
    delete = true
  }
}

resource "consul_keys" "eip_id" {
  count = 3
  key {
    path  = "brokerEip/${local.broker_clusterId}/eipId/${count.index}"
    value = ucloud_eip.broker_eip.*.id[count.index]
    delete = true
  }
}

resource "consul_keys" "broker_state" {
  count = 3
  key {
    path  = "brokerEip/${local.broker_clusterId}/eip_association/${count.index}"
    value = ""
    delete = true
  }
}

provider "nomad" {
  address = "http://${local.nomad_server_ip}:4646"
  region  = local.region
}


data "template_file" "broker-job" {
  template = file(local.broker-job-hcl)
  vars     = {
    job-name            = "broker-${local.broker_clusterId}"
    cmd                 = "./mqbroker"
    cluster-id          = local.broker_clusterId
    namesvr_clusterId   = var.namesvr_clusterId
    region              = local.region
    broker-image        = "${var.rocketmq_docker_image}:${var.rocketmq_version}"
    cpu                 = var.broker_size * var.base_cpu
    memory              = var.broker_size * var.base_memory
    rockermq-version    = var.rocketmq_version
    brokersvc-name      = local.brokersvc-name
    node-class          = "broker"
    task-limit-per-az   = var.allow_multiple_tasks_in_az ? length(local.az) : 1
    terraform-image     = var.terraform-image
    ucloud_pub_key      = var.ucloud_pubkey
    ucloud_secret       = var.ucloud_secret
    project_id          = local.projectId
    region              = local.region
    ucloud_api_base_url = var.ucloud_api_base_url
    internal            = var.internal_use ? "yes" : ""
  }
}

resource "nomad_job" "broker" {
  depends_on = [consul_keys.eip_id, consul_keys.eip_public_ip]
  jobspec = data.template_file.broker-job.rendered
}