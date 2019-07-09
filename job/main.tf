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
locals {
  redis-job-script = "${file("./redis-job.hcl")}"
}
resource "nomad_job" "redis" {
  count = 1
  jobspec = "${local.redis-job-script}"
}