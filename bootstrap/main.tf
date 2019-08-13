data "template_file" "bootstrap_script" {
  template = file("${path.module}/bootstrap.sh")
  vars = {
    terraform_project_url = var.terraform_project_url
    project_dir = var.project_dir
    branch = var.branch
    controller_image = var.controller_image
    controller_pod_label = var.controller_pod_label
    k8s_namespace = var.k8s_namespace
    region = var.region
    ucloud_pub_key = var.ucloud_pub_key
    ucloud_secret = var.ucloud_secret
    project_id = var.project_id
    mgrVpcCidr = var.mgrVpcCidr
    clientVpcCidr = var.clientVpcCidr
    allow_ip = var.allow_ip
    az = join(", ", formatlist("\"%s\"", var.az))
    consul_server_image_id = var.consul_server_image_id
    consul_server_root_password = var.consul_server_root_password
    consul_server_type = var.consul_server_type
    nomad_client_broker_type = var.nomad_client_broker_type
    nomad_client_image_id = var.nomad_client_image_id
    nomad_client_namesvr_type = var.nomad_client_namesvr_type
    nomad_client_root_password = var.nomad_client_root_password
    nomad_server_image_id = var.nomad_server_image_id
    nomad_server_root_password = var.nomad_server_root_password
    nomad_server_type = var.nomad_server_type
    cluster_id = var.cluster_id
    TF_PLUGIN_CONSUL_VERSION = var.TF_PLUGIN_CONSUL_VERSION
    TF_PLUGIN_NULL_VERSION = var.TF_PLUGIN_NULL_VERSION
    TF_PLUGIN_TEMPLATE_VERSION = var.TF_PLUGIN_TEMPLATE_VERSION
    TF_PLUGIN_UCLOUD_VERSION = var.TF_PLUGIN_UCLOUD_VERSION
  }
}

resource "kubernetes_config_map" "bootstrap_script" {
  metadata {
    name = "bootstrap-script"
  }
  data = {
    "bootstrap.sh" = data.template_file.bootstrap_script.rendered
  }
}

//resource "kubernetes_job" "bootstrap_job" {
//  metadata {
//    namespace = var.k8s_namespace
//    name = "bootstrap"
//  }
//  spec {
//    template {
//      metadata {}
//      spec {
//        container {
//          name = "bootstrap"
//          image = var.controller_image
//          command = ["sh", "/bootstrap/bootstrap.sh"]
//          volume_mount {
//            name = "bootstrap"
//            mount_path = "/bootstrap"
//          }
//        }
//        volume {
//          config_map {
//            name = "bootstrap_script"
//          }
//        }
//      }
//    }
//  }
//}
resource "kubernetes_pod" "test" {
  metadata {
    name = "test"
    namespace = var.k8s_namespace
  }
  spec {
    container {
      name = "bootstrap"
      image = var.controller_image
      command = ["tail", "-f", "/dev/null"]
      volume_mount {
        name = "bootstrap"
        mount_path = "/bootstrap"
      }
    }
    volume {
      config_map {
        name = "bootstrap-script"
      }
    }
  }
}

//resource "kubernetes_deployment" "controller" {
//  metadata {
//    namespace = var.k8s_namespace
//    name = "rkq-controller"
//  }
//  spec {
//    replicas = 3
//
//    selector {
//      match_labels = {
//        app = var.controller_pod_label
//      }
//    }
//
//    template {
//      metadata {
//        labels = {
//          app = var.controller_pod_label
//        }
//      }
//      spec {
//        container {
//          name = "controller"
//          image = var.controller_image
//          command = [
//            "tail"]
//          args = [
//            "-f",
//            "/dev/null"]
//          resources {
//            limits {
//              cpu = "1"
//              memory = "1024Mi"
//            }
//            requests {
//              cpu = "1"
//              memory = "1024Mi"
//            }
//          }
//        }
//      }
//    }
//  }
//}
//
//resource kubernetes_service ctrlService {
//  metadata {
//    namespace = var.k8s_namespace
//    name = "nomad-ctrl-service"
//  }
//  spec {
//    selector = {
//      app = var.controller_pod_label
//    }
//    port {
//      port = 80
//      target_port = 80
//    }
//  }
//}