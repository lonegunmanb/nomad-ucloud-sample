job "console-${cluster-id}" {
  datacenters = ["${region}"]
  region = "${region}"
  constraint {
    attribute = "$${node.class}"
    value = "${node-class}"
  }
  group "console" {
    task "console" {
      driver = "docker"
      config {
        image = "${console-image}"
        network_mode = "host"
      }
      template {
        data = <<EOH
          JAVA_OPTS="-Drocketmq.namesrv.addr=localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr0"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr1"}};localhost:{{env "NOMAD_PORT_namesvc${cluster-id}_namesvr2"}} -Dcom.rocketmq.sendMessageWithVIPChannel=false -Dserver.port={{env "NOMAD_PORT_tcp"}} -Dserver.contextPath=/console-${cluster-id}"
          EOH

        destination = "local/file.env"
        env = true
      }
      resources {
        cpu = 500
        memory = 2048
        network {
          port "tcp" {}
        }
      }
      service {
        name = "console-${cluster-id}"
        port = "tcp"
        tags = ["urlprefix-/console-${cluster-id}"]
        check {
          type = "tcp"
          port = "tcp"
          interval = "10s"
          timeout = "2s"
        }
      }
    }
    task "namesvc${cluster-id}" {
      driver = "exec"
      config {
        command = "consul"
        args    = [
          "connect", "proxy",
          "-service", "namesvc-sidecar-${cluster-id}-0",
          "-upstream", "namesvc-${cluster-id}-0:$${NOMAD_PORT_namesvr0}",
          "-service", "namesvc-sidecar-${cluster-id}-1",
          "-upstream", "namesvc-${cluster-id}-1:$${NOMAD_PORT_namesvr1}",
          "-service", "namesvc-sidecar-${cluster-id}-2",
          "-upstream", "namesvc-${cluster-id}-2:$${NOMAD_PORT_namesvr2}",
        ]
      }
      resources {
        network {
          port "namesvr0" {}
          port "namesvr1" {}
          port "namesvr2" {}
        }
      }
    }
    task "lb-backend-terraform" {
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
      resources {
        cpu = 100
        memory = 50
      }
      template {
        data = <<EOF
        set -e
        cd /tf
        cat main.tf
        terraform init -plugin-dir=/plugin
        terraform apply --auto-approve -lock=false
        tail -f /dev/null
        EOF
        destination = "local/tf/tf.sh"
        change_mode = "noop"
      }
      template {
        data = <<EOF
            terraform {
            backend "consul" {
                address = "{{with service "consul"}}{{with index . 0}}{{.Address}}:8500{{end}}{{end}}"
                scheme = "http"
                path = "namesvr-lb/${cluster-id}/console"
              }
            }

            provider "ucloud" {
              public_key = "${ucloudPubKey}"
              private_key = "${ucloudPriKey}"
              project_id = "${projectId}"
              region = "${region}"
              base_url = "${ucloud_api_base_url}"
            }

            resource "ucloud_lb_attachment" "console" {
                load_balancer_id = "${load_balancer_id}"
                listener_id      = "${consoleListenerId}"
                resource_id      = "{{env "node.unique.name"}}"
                port             = {{env "NOMAD_PORT_console_tcp"}}
            }
            EOF
        destination = "local/tf/main.tf"
        change_mode = "noop"
      }
      //    template {
      //      data = "TF_LOG=trace"
      //      destination = "local/tf/env"
      //      env = true
      //    }
    }
  }
  reschedule {
    delay          = "30s"
    delay_function = "exponential"
    max_delay      = "120s"
    unlimited      = true
  }
}
