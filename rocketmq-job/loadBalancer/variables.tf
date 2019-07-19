variable az {}
variable nomad-server-ip {}
variable region {}
variable terraform-image {}
variable clusterId {}
variable jobName {}

locals {
  job-hcl = "${path.module}/job.hcl"
  tf-tpl = "${path.module}/lb.tf.tpl"
  tf-vars-tpl = "${path.module}/terraform.tfvars.tpl"
  tf-vars-content = "${file(local.tf-vars-tpl)}"
}