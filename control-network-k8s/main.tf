provider "kubernetes" {
  host = "https://104.196.242.174"

  client_certificate     = file("~/.kube/client-cert.pem")
  client_key             = file("~/.kube/client-key.pem")
  cluster_ca_certificate = file("~/.kube/cluster-ca-cert.pem")
}

resource kubernetes_pod controller {
  metadata {
    name = "controller"
    labels {
      app = "ctrl"
    }
  }
  spec {
    container {
      name = "controller"
      image = var.controllerImage
      env {
        name = "TF_VAR_consul_backend"
        value = ""
      }
    }
  }
}

resource kubernetes_service ctrlService {
  metadata {
    namespace = var.namespace
    name = "nomad-ctrl-service"
  }
  spec {
    selector {
      app = kubernetes_pod.controller.metadata.0.labels.app
    }
    port {
      port = 80
      target_port = 80
    }
  }
}