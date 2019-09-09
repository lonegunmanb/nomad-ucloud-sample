provider nomad {
  address = local.nomad_server_access_url
  region  = local.region
}

data "template_file" "fabio_job" {
  template = file("${path.module}/job.hcl.tplt")
  vars     = {
    region       = local.region
    fabio-image  = var.fabio_image
    lb-port      = var.lb_port
    consul-lb-ip = local.consul_lb_ip
    node-class   = "nameServer"
  }
}

resource "nomad_job" "fabio" {
  jobspec = data.template_file.fabio_job.rendered
}