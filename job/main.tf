data "terraform_remote_state" "nomad" {
  backend = "local"
  config = {
    path = "../terraform.tfstate"
  }
}

locals {
  az = "${data.terraform_remote_state.nomad.az}"
}

provider "nomad" {
  address = "http://${data.terraform_remote_state.nomad.nomad_servers_ips[0]}:4646"
  region  = "cn-bj2"
}

data "template_file" "redis-job" {
  template = "${file("./redis-job.hcl")}"
  vars = {
    job-name = "redis"
    redis-server-image = "${var.redis-server-image}"
    web-server-image = "${var.web-server-image}"
  }
}

resource "nomad_job" "redis" {
  count = 1
  jobspec = "${data.template_file.redis-job.rendered}"
}