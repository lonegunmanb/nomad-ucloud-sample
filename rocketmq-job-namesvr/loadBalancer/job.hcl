job "${jobName}" {
  datacenters = ["${region}"]
  task "terraform" {
    driver = "docker"
    config {
      image = "${terraform-image}"
      command = "sh"
      args = ["/tf/tf.sh"]
      volumes = [
        "local/tf:/tf",
        "secret/tf:/secret",
        "/plugin:/plugin"
      ]
      network_mode = "host"
    }
    meta {
      clusterId = "${cluster-id}"
    }
    template {
      data = <<EOF
        set -e
        cd /tf
        cat main.tf
        terraform init
        while true
        do
          terraform apply --auto-approve -lock=false -var-file="/secret/terraform.tfvars"
          sleep 10
        done
        EOF
      destination = "local/tf/tf.sh"
      change_mode = "noop"
    }
    template {
      data = <<EOF
        ${tfvars}
        EOF
      destination = "secret/tf/terraform.tfvars"
      change_mode = "noop"
    }
    template {
      data = <<EOF
            ${tf}
            EOF
      destination = "local/tf/main.tf"
      change_mode = "noop"
    }
    # add an output file to guard terraform apply, fail execution when tf code's not exist
    template {
      data = <<EOF
              output lbId {
                value = "$${ucloud_lb.rocketMQLoadBalancer.*.id}"
              }
             EOF
      destination = "local/tf/outputs.tf"
    }
//    template {
//      data = "TF_LOG=trace"
//      destination = "local/tf/env"
//      env = true
//    }
  }
}