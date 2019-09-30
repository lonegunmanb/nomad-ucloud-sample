output "lb_ip" {
  value = var.legacy_lb_private_ip == "" ? (length(ucloud_lb.lb) == 0 ? "" :ucloud_lb.lb.*.private_ip[0]) : var.legacy_lb_private_ip
}

output "lb_id" {
  value = var.legacy_lb_id == "" ? (length(ucloud_lb.lb) == 0 ? "" : ucloud_lb.lb.*.id[0]) : var.legacy_lb_id
}

output "setup_loopback_script" {
  value = data.template_file.add-loopback-script.rendered
}
