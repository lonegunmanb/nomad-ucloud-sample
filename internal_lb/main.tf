locals {
  add_loopback_script_path      = "${path.module}/add-loopback.sh.tplt"
}
resource ucloud_lb lb {
  name = var.name
  internal = true
  tag = var.tag
  vpc_id = var.vpc_id
  subnet_id = var.subnet_id
}

resource ucloud_lb_listener consul_listener {
  count = length(var.ports)
  load_balancer_id = ucloud_lb.lb.id
  protocol = "tcp"
  name = var.listenerName == "" ? var.ports[count.index] : "${var.listenerName}-${var.ports[count.index]}"
  port = var.ports[count.index]
}

locals {
  attachments = setproduct(var.instance_ids, var.ports)
  listener_map = zipmap(var.ports, ucloud_lb_listener.consul_listener.*.id)
}

resource "ucloud_lb_attachment" "attachment" {
  count = var.attachment_count == 0 ? length(local.attachments) : var.attachment_count
  load_balancer_id = ucloud_lb.lb.id
  resource_id = local.attachments[count.index][0]
  port = local.attachments[count.index][1]
  listener_id = local.listener_map[local.attachments[count.index][1]]
  lifecycle {
    ignore_changes = [listener_id, resource_id]
  }
}

data "template_file" "add-loopback-script" {
  template = file(local.add_loopback_script_path)
  vars = {
    vip = ucloud_lb.lb.private_ip
    device = var.device
  }
}