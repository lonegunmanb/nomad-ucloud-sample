variable az {}
variable nomad-server-ip {}
variable region {}
variable terraform-image {}
variable clusterId {}
variable jobName {}
variable vpcId {}
variable subnetId {}
variable projectId {}
variable ucloud_pubkey {}
variable ucloud_secret {}
variable ucloud_api_base_url {}
variable consul_access_url {}
locals {
  job-hcl = "${path.module}/job.hcl"
  tf-tpl  = "${path.module}/lb.tf.tpl"
  tf-vars-tpl = "${path.module}/terraform.tfvars.tpl"
}

