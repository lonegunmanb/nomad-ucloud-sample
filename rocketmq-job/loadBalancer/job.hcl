job "${jobName}" {
  datacenters = ["${az}"]
  task "terraform" {
    driver = "docker"
    config {
      image = "${terraform-image}"
      command = "sh"
      args = ["/tf/tf.sh"]
      volumes = [
        "local/tf:/tf",
        "/plugin:/plugin"
      ]
    }
    meta {
      clusterId = "${cluster-id}"
    }
    template {
      data = <<EOF
        cd /tf
        cat main.tf
        terraform init
        terraform apply --auto-approve
        tail -f /dev/null
        EOF
      destination = "local/tf/tf.sh"
    }
    template {
      data = <<EOF
        ${tfvars}
        EOF
      destination = "local/tf/terraform.tfvars"
    }
    template {
      data = <<EOF
            ${tf}
            EOF
      destination = "local/tf/main.tf"
    }
  }
}