resource "kubernetes_deployment" "controller" {
  metadata {
    namespace = var.k8s_namespace
    name = "rkq-controller"
  }
  spec {
    replicas = 3

    selector {
      match_labels = {
        app = var.controller_pod_label
      }
    }

    template {
      metadata {
        labels = {
          app = var.controller_pod_label
        }
      }
      spec {
        container {
          name = "controller"
          image = var.controller_image
          command = ["tail"]
          args = ["-f", "/dev/null"]
          resources {
            limits {
              cpu    = "1"
              memory = "1024Mi"
            }
            requests {
              cpu    = "1"
              memory = "1024Mi"
            }
          }
        }
      }
    }
  }
}

resource kubernetes_service ctrlService {
  metadata {
    namespace = var.k8s_namespace
    name = "nomad-ctrl-service"
  }
  spec {
    selector = {
      app = var.controller_pod_label
    }
    port {
      port = 80
      target_port = 80
    }
  }
}