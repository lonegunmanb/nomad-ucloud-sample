data template_file tf-content {
  template = "${file(local.tf-tpl)}"
  vars {
    cluster-id = "${var.clusterId}"
  }
}

data "template_file" "job" {
  template = "${file(local.job-hcl)}"
  vars {
    region = "${var.region}"
    cluster-id = "${var.clusterId}"
    terraform-image = "${var.terraform-image}"
    tfvars = "${local.tf-vars-content}"
    tf = "${data.template_file.tf-content.rendered}"
    jobName = "${var.jobName}"
  }
}

provider "nomad" {
  address = "http://${var.nomad-server-ip}:4646"
  region  = "${var.region}"
}

resource "nomad_job" "terraform_docker" {
  jobspec = "${data.template_file.job.rendered}"
}

