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
locals {
  job-hcl = "${path.module}/job.hcl"
  tf-tpl = "${path.module}/lb.tf.tpl"
}