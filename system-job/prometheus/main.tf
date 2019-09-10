variable "tagPrefix" {}
variable "region" {}
variable "prometheus-image" {}

data "template_file" "job" {
  template = file("${path.module}/job.hcl.tplt")
  vars     = {
    region     = var.region
    node-class = "nameServer"
    tagPrefix  = var.tagPrefix
    prometheusImage = var.prometheus-image
  }
}

resource "nomad_job" "prometheus" {
  jobspec = data.template_file.job.rendered
}