data "template_file" "fabio_job" {
  template = file("${path.module}/job.hcl.tplt")
  vars     = {
    jobName      = var.job_name
    region       = var.region
    fabio-image  = var.fabio_image
    lb-port      = var.lb_port
    node-class   = "nameServer"
    tagprefix    = var.fabio_tag_prefix
  }
}

resource "nomad_job" "fabio" {
  jobspec = data.template_file.fabio_job.rendered
}