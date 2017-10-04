job "grafana" {
  region      = "global"
  datacenters = ["sfo"]
  type        = "service"

  group "grafana" {
    task "server" {
      driver = "docker"

      constraint {
        attribute = "${node.unique.name}"
        operator = "="
        value = "node2"
      }

      config {
        image = "grafana/grafana:4.5.2"
        volumes = [
          "/data/grafana:/var/lib/grafana"
        ]
        port_map {
          http = 3000
        }
      }

      env {
        GF_SERVER_HTTP_PORT = "${NOMAD_PORT_http}"
        GF_AUTH_ANONYMOUS_ENABLED = "true"
        GF_AUTH_ANONYMOUS_ORG_ROLE = "Admin"
      }

      service {
        name = "grafana"
        port = "http"
        tags = [
          "traefik.enable=true"
        ]
        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        cpu = 150
        memory = 128
        network {
          port "http" {}
        }
      }
    }
  }
}