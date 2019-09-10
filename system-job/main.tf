provider nomad {
  address = local.nomad_server_access_url
  region  = local.region
}

module "namesvr_index_http_endpoint" {
  source      = "./fabio"
  fabio_image = var.fabio_image
  job_name    = "namesvrIndexFabio"
  lb_port     = var.namesvr_fabio_port
  region      = local.region
}

locals {
  prometheus_fabio_tag_prefix = "urlprefix-prometheus-"
}

module "prometheus_fabio" {
  source           = "./fabio"
  fabio_image      = var.fabio_image
  job_name         = "prometheusFabio"
  lb_port          = var.prometheus_port
  fabio_tag_prefix = local.prometheus_fabio_tag_prefix
  region           = local.region
}

module "prometheus_job" {
  source           = "./prometheus"
  tagPrefix        = local.prometheus_fabio_tag_prefix
  region           = local.region
  prometheus-image = var.prometheus_image
}