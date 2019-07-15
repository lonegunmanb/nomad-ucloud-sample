task "namesvc${cluster-id}${index}" {
  driver = "exec"
  config {
    command = "consul"
    args    = [
      "connect", "proxy",
      "-service", "namesvc-sidecar-${cluster-id}-${index}",
      "-upstream", "namesvc-${cluster-id}-${index}:$${NOMAD_PORT_tcp}",
    ]
  }
  resources {
    network {
      port "tcp" {}
    }
  }
}