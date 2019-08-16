output "lb_ip" {
  value = ucloud_lb.lb.private_ip
}

output "lb_id" {
  value = ucloud_lb.lb.id
}

output "setup_loopback_script" {
  value = data.template_file.add-loopback-script.rendered
}