locals {
  controller_image_repo_secret_name = "controller-image-repo-secret-${var.cluster_id}"
}
resource "null_resource" "controller_image_repo_secret" {
  provisioner "local-exec" {
    command = "kubectl create secret docker-registry ${local.controller_image_repo_secret_name} --docker-server=${var.controller_image_repo} --docker-username=${var.controller_image_username} --docker-password=${var.controller_image_password} -n ${var.k8s_namespace}"
  }
  provisioner "local-exec" {
    when = "destroy"
    command = "kubectl delete secret -n ${var.k8s_namespace} ${local.controller_image_repo_secret_name}"
    on_failure = "continue"
  }
}

resource "kubernetes_secret" "ucloud_key" {
  metadata {
    name      = "ucloud-key-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    ucloud-pub-key = var.ucloud_pub_key
    ucloud-secret  = var.ucloud_secret
  }
}

data "template_file" "bootstrap_script" {
  template = file("${path.module}/bootstrap.sh.tplt")
  vars     = {
    consul_backend_root_password    = var.consul_backend_root_password
    consul_backend_image_id         = var.consul_backend_image_id
    consul_backend_charge_type      = var.consul_backend_charge_type
    consul_backend_charge_duration  = var.consul_backend_charge_duration
    terraform_project_url           = var.terraform_project_url
    project_dir                     = var.project_dir
    branch                          = var.branch
    controller_image                = var.controller_image
    k8s_namespace                   = var.k8s_namespace
    consul_backend_data_volume_size = var.consul_backend_data_volume_size
    consul_backend_instance_type    = var.consul_backend_instance_type
    region                          = var.region
    region_id                       = var.region_id
    ucloud_pub_key                  = var.ucloud_pub_key
    ucloud_secret                   = var.ucloud_secret
    project_id                      = var.project_id
    controller_cidr                 = var.controller_cidr
    mgrVpcCidr                      = var.mgrVpcCidr
    clientVpcCidr                   = var.clientVpcCidr
    legacy_vpc_id                   = var.legacy_vpc_id
    legacy_subnet_id                = var.legacy_subnet_id
    ipv6_api_url                    = var.ipv6_api_url
    allow_ip                        = var.allow_ip
    az                              = join(", ", formatlist("\"%s\"", var.az))
    consul_server_image_id          = local.consul_server_image_id
    consul_server_root_password     = local.consul_server_root_password
    consul_server_type              = local.consul_server_type
    nomad_client_broker_type        = local.nomad_client_broker_type
    nomad_client_broker_image_id    = local.nomad_client_broker_image_id
    nomad_client_namesvr_image_id   = local.nomad_client_namesvr_image_id
    nomad_client_namesvr_type       = local.nomad_client_namesvr_type
    nomad_client_broker_root_password      = local.nomad_client_broker_root_password
    nomad_client_namesvr_root_password = local.nomad_client_namesvr_root_password
    nomad_server_image_id           = local.nomad_server_image_id
    nomad_server_root_password      = local.nomad_server_root_password
    nomad_server_type               = local.nomad_server_type
    cluster_id                      = var.cluster_id
    broker_count                    = local.broker_count
    name_server_count               = local.name_server_count
    nomad_server_count              = local.nomad_server_count
    name_server_local_disk_type     = local.name_server_local_disk_type
    name_server_udisk_type          = local.name_server_udisk_type
    name_server_data_disk_size      = local.name_server_data_disk_size
    broker_local_disk_type          = local.broker_local_disk_type
    broker_udisk_type               = local.broker_udisk_type
    broker_data_disk_size           = local.broker_data_disk_size
    name_server_use_udisk           = local.name_server_use_udisk
    broker_use_udisk                = local.broker_use_udisk
    nomad_server_use_udisk          = local.nomad_server_use_udisk
    nomad_server_local_disk_type    = local.nomad_server_local_disk_type
    nomad_server_udisk_type         = local.nomad_server_udisk_type
    nomad_server_data_disk_size     = local.nomad_server_data_disk_size
    consul_server_use_udisk         = local.consul_server_use_udisk
    consul_server_udisk_type        = local.consul_server_udisk_type
    consul_server_local_disk_type   = local.consul_server_local_disk_type
    consul_server_data_disk_size    = local.consul_server_data_disk_size
    fabio_image_id                  = var.fabio_image_id
    prometheus_image                = var.prometheus_image_id
    namesvr_http_endpoint_port      = var.namesvr_http_endpoint_port
    prometheus_port                 = var.prometheus_port
    consul_server_charge_type       = local.consul_server_charge_type
    consul_server_charge_duration   = local.consul_server_charge_duration
    nomad_server_charge_type        = local.nomad_server_charge_type
    nomad_server_charge_duration    = local.nomad_server_charge_duration
    client_charge_type              = local.client_charge_type
    client_charge_duration          = local.client_charge_duration
    env_name                        = var.env_name
  }
}

data "template_file" "destroy-script" {
  template = file("${path.module}/destroy.sh.tplt")
  vars     = {
    project_dir = var.project_dir
  }
}

resource "kubernetes_config_map" "bootstrap-script" {
  metadata {
    name      = "bootstrap-script-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    "bootstrap.sh" = data.template_file.bootstrap_script.rendered
    "destroy.sh"   = data.template_file.destroy-script.rendered
  }
}

resource kubernetes_persistent_volume_claim code_volume {
  metadata {
    name      = "rktmq-bootstrap-code-volume-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  spec {
    access_modes       = [
      "ReadWriteOnce"]
    storage_class_name = var.k8s_storage_class_name

    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}

locals {
  bootstraper_pod_name = "bootstrapper-${var.cluster_id}"
  bootstrap_script_dir = "/bootstrap"
}
resource "kubernetes_pod" "bootstraper" {
  depends_on = [
    kubernetes_config_map.bootstrap-script]
  metadata {
    name      = local.bootstraper_pod_name
    namespace = var.k8s_namespace
  }
  spec {
    container {
      name    = "bootstrap"
      image   = var.bootstrapper_image
      command = [
        "sh",
        "/bootstrap/bootstrap.sh"]
      volume_mount {
        name       = "bootstrap-script"
        mount_path = local.bootstrap_script_dir
      }
      volume_mount {
        name       = "code"
        mount_path = "/project"
      }
      //DO NOT remove security_context or the pod will be recreated on re-apply
      security_context {
        allow_privilege_escalation = false
        privileged                 = false
        read_only_root_filesystem  = false
        run_as_group               = 0
        run_as_non_root            = false
        run_as_user                = 0
      }
      env {
        name  = "TF_VAR_ucloud_api_base_url"
        value = var.ucloud_api_base_url
      }
      env {
        name = "TF_VAR_ucloud_pub_key"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.ucloud_key.metadata[0].name
            key  = "ucloud-pub-key"
          }
        }
      }
      env {
        name  = "TF_VAR_ucloud_secret"
        value_from {
          secret_key_ref {
            name = kubernetes_secret.ucloud_key.metadata[0].name
            key = "ucloud-secret"
          }
        }
      }
    }
    volume {
      name = "bootstrap-script"
      config_map {
        name = kubernetes_config_map.bootstrap-script.metadata[0].name
      }
    }
    volume {
      name = "code"
      persistent_volume_claim {
        claim_name = kubernetes_persistent_volume_claim.code_volume.metadata[0].name
        read_only  = false
      }
    }
    //DO NOT remove security_context or the pod will be recreated on re-apply
    security_context {
      fs_group            = 2000
      run_as_group        = 0
      run_as_non_root     = false
      run_as_user         = 0
      supplemental_groups = [
        2000,
      ]
    }
  }
  provisioner "local-exec" {
    when    = "destroy"
    command = "kubectl -n ${var.k8s_namespace} exec ${local.bootstraper_pod_name} sh ${local.bootstrap_script_dir}/destroy.sh"
  }
}

provider "ucloud" {
  public_key  = var.ucloud_pub_key
  private_key = var.ucloud_secret
  project_id  = var.project_id
  region      = var.region
  base_url    = var.ucloud_api_base_url
}

data "ucloud_lbs" "consul_backend_Lb" {
  depends_on = [
    kubernetes_pod.bootstraper]
  name_regex = "consulBackendLb-${var.cluster_id}"
}

data "ucloud_lbs" "consul_rktmq_lb" {
  depends_on = [
    kubernetes_pod.bootstraper]
  name_regex = "consulServer-${var.cluster_id}"
}

data "ucloud_lbs" "nomadServerLb" {
  depends_on = [kubernetes_pod.bootstraper]
  name_regex = "nomadServerLb-${var.cluster_id}"
}

data "ucloud_lbs" "nameServerLb" {
  depends_on = [kubernetes_pod.bootstraper]
  name_regex = "nameServerInternalLb-${var.cluster_id}"
}

module "nameServerLbIpv6" {
  source         = "../ipv6"
  api_server_url = var.ipv6_api_url
  region_id      = var.region_id
  resourceIds    = [data.ucloud_lbs.nameServerLb.lbs[0].id]
}

locals {
  consulBackendLbId          = data.ucloud_lbs.consul_backend_Lb.lbs[0].id
  consulRktmqLbId            = data.ucloud_lbs.consul_rktmq_lb.lbs[0].id
  nomadServerLbId            = data.ucloud_lbs.nomadServerLb.lbs[0].id
  allow_multiple_tasks_in_az = length(var.az) == length(distinct(var.az)) ? false : true
  nameServerLbIp             = var.env_name == "public" ? module.nameServerLbIpv6.ipv6s[0] : data.ucloud_lbs.nameServerLb.lbs[0].private_ip
}

module "consulBackendLbIpv6" {
  source         = "../ipv6"
  api_server_url = var.ipv6_api_url
  region_id      = var.region_id
  resourceIds    = [local.consulBackendLbId]
}

module "consulRktmqLbIpv6" {
  source         = "../ipv6"
  api_server_url = var.ipv6_api_url
  region_id      = var.region_id
  resourceIds    = [local.consulRktmqLbId]
}

module "nomadServerLbIpv6" {
  source         = "../ipv6"
  api_server_url = var.ipv6_api_url
  region_id      = var.region_id
  resourceIds    = [local.nomadServerLbId]
}

resource "kubernetes_config_map" "backend-script" {
  metadata {
    name      = "backend-script-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    "backend.tfvars" = "address = \"http://[${module.consulBackendLbIpv6.ipv6s[0]}]:8500\""
    "remote.tfvars"  = "remote_state_backend_url = \"http://[${module.consulBackendLbIpv6.ipv6s[0]}]:8500\""
  }
}

data "ucloud_vpcs" "client_vpc" {
  depends_on = [kubernetes_pod.bootstraper]
  count = var.legacy_vpc_id == "" ? 1 : 0
  name_regex = "nomadClientVpc-${var.cluster_id}"
}

data "ucloud_subnets" "client_subnet" {
  depends_on = [kubernetes_pod.bootstraper]
  count = var.legacy_vpc_id == "" ? 1 : 0
  name_regex = "nomadClientSubnet-${var.cluster_id}"
}

locals {
  client_vpc_id = var.legacy_vpc_id == "" ? data.ucloud_vpcs.client_vpc[0].vpcs[0].id : var.legacy_vpc_id
  client_subnet_id = var.legacy_subnet_id == "" ? data.ucloud_subnets.client_subnet[0].subnets[0].id : var.legacy_subnet_id
}

locals {
  nomad_access_url = "http://[${module.nomadServerLbIpv6.ipv6s[0]}]:4646"
  consulRktmq_access_url = "http://[${module.consulRktmqLbIpv6.ipv6s[0]}]:8500"
  controller_pod_label = "rktmq-${var.cluster_id}"
  haproxy_pod_label    = "haproxy-${var.cluster_id}"
  quotedAz = [for a in var.az: "\"${a}\""]
}

resource "kubernetes_deployment" "controller" {
  depends_on = [
    null_resource.controller_image_repo_secret,
    module.nomadServerLbIpv6.ipv6s,
    module.consulRktmqLbIpv6.ipv6s,
  ]
  metadata {
    namespace = var.k8s_namespace
    name      = "rkq-controller-${var.cluster_id}"
  }
  spec {
    replicas = var.controller_count

    selector {
      match_labels = {
        app = local.controller_pod_label
      }
    }

    template {
      metadata {
        labels = {
          app = local.controller_pod_label
        }
      }
      spec {
        container {
          name  = "controller"
          image = var.controller_image

          env {
            name  = "TF_VAR_remote_state_backend_url"
            value = "http://[${module.consulBackendLbIpv6.ipv6s[0]}]:8500"
          }
          env {
            name  = "TF_VAR_nomad_cluster_id"
            value = var.cluster_id
          }
          env {
            name  = "TF_VAR_allow_multiple_tasks_in_az"
            value = local.allow_multiple_tasks_in_az
          }
          env {
            name  = "TF_VAR_ucloud_api_base_url"
            value = var.ucloud_api_base_url
          }
          env {
            name  = "TF_VAR_provision_from_kun"
            value = "true"
          }
          env {
            name = "TF_VAR_nomad_access_url"
            value = local.nomad_access_url
          }
          env {
            name = "TF_VAR_consul_access_url"
            value = local.consulRktmq_access_url
          }
          env {
            name = "TF_VAR_vpcId"
            value = local.client_vpc_id
          }
          env {
            name = "TF_VAR_subnetId"
            value = local.client_subnet_id
          }
          env {
            name = "TF_VAR_region"
            value = var.region
          }
          env {
            name = "TF_VAR_az"
            value = "[${join(",", local.quotedAz)}]"
          }
          env {
            name = "TF_VAR_project_id"
            value = var.project_id
          }
          env {
            name = "TF_VAR_ucloud_pubkey"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ucloud_key.metadata[0].name
                key  = "ucloud-pub-key"
              }
            }
          }
          env {
            name  = "TF_VAR_ucloud_secret"
            value_from {
              secret_key_ref {
                name = kubernetes_secret.ucloud_key.metadata[0].name
                key = "ucloud-secret"
              }
            }
          }
          env {
            name = "TF_VAR_internal_use"
            value = var.env_name == "private" ? "true" : "false"
          }
          env {
            name = "NAMESVR_INDEX_IP"
            value = local.nameServerLbIp
          }
          dynamic "env" {
            for_each = var.controller_env_map
            content {
              name = env.key
              value = env.value
            }
          }
          resources {
            limits {
              cpu    = var.controller_limit_cpu
              memory = var.controller_limit_memory
            }
            requests {
              cpu    = var.controller_request_cpu
              memory = var.controller_request_memory
            }
          }
          volume_mount {
            name       = "backend-script"
            mount_path = "/backend"
          }
        }
        volume {
          name = "backend-script"
          config_map {
            name = kubernetes_config_map.backend-script.metadata[0].name
          }
        }
        image_pull_secrets {
          name = local.controller_image_repo_secret_name
        }
      }
    }
  }
}

resource kubernetes_service ctrlService {
  metadata {
    namespace = var.k8s_namespace
    name      = "nomad-ctrl-service-${var.cluster_id}"
  }
  spec {
    selector = {
      app = local.controller_pod_label
    }
    port {
      port        = var.controller_svc_port
      target_port = var.controller_pod_port
    }
  }
}

data "template_file" "haproxy_cfg" {
  template = file("${path.module}/haproxy.cfg")
  vars     = {
    nomad_ip                 = module.nomadServerLbIpv6.ipv6s[0]
    nomad_port               = 4646
    dest_nomad_port          = 4646
    consul_backend_ip        = module.consulBackendLbIpv6.ipv6s[0]
    consul_backend_port      = 8500
    dest_consul_backend_port = 8500
    consul_rktmq_ip          = module.consulRktmqLbIpv6.ipv6s[0]
    consul_rktmq_port        = 8501
    dest_consul_rktmq_port   = 8500
    prometheus_port          = 9090
    prometheus_ip            = module.nameServerLbIpv6.ipv6s[0]
    dest_prometheus_port     = 9090
    namesvr_port             = 8080
    namesvr_ip               = local.nameServerLbIp
    dest_namesvr_port        = 8080
  }
}

resource "kubernetes_config_map" "haproxy_cfg" {
  metadata {
    name      = "haproxy-cfg-${var.cluster_id}"
    namespace = var.k8s_namespace
  }
  data = {
    "haproxy.cfg" = data.template_file.haproxy_cfg.rendered
  }
}


resource "kubernetes_deployment" "haproxy" {
  depends_on = [kubernetes_deployment.controller]
  metadata {
    namespace = var.k8s_namespace
    name      = "haproxy-${var.cluster_id}"
  }
  spec {
    replicas = 2

    selector {
      match_labels = {
        app = local.haproxy_pod_label
      }
    }

    template {
      metadata {
        labels = {
          app = local.haproxy_pod_label
        }
      }
      spec {
        container {
          name  = "haproxy"
          image = var.haproxy_image
          port {
            name = "nomad"
            container_port = 4646
          }
          port {
            name = "consul-backend"
            container_port = 8500
          }
          port {
            name = "consul-rktmq"
            container_port = 8501
          }
          port {
            name = "prometheus"
            container_port = 9090
          }
          port {
            name = "namesvr"
            container_port = 8080
          }
          volume_mount {
            name       = "haproxycfg"
            mount_path = "/usr/local/etc/haproxy"
          }
        }
        volume {
          name = "haproxycfg"
          config_map {
            name = kubernetes_config_map.haproxy_cfg.metadata[0].name
          }
        }
      }
    }
  }
}

resource kubernetes_service maintain {
  metadata {
    namespace = var.k8s_namespace
    name      = var.cluster_id
  }
  spec {
    selector = {
      app = local.haproxy_pod_label
    }
    port {
      name = "nomad"
      port        = 4646
      target_port = 4646
    }
    port {
      name = "consul-backend"
      port = 8500
      target_port = 8500
    }
    port {
      name = "consul-rktmq"
      port = 8501
      target_port = 8501
    }
    port {
      name = "prometheus"
      port = 9090
      target_port = 9090
    }
    port {
      name = "namesvr"
      port = 8080
      target_port = 8080
    }
  }
}
