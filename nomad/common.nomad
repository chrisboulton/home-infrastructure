job "node-common" {
  region = "global"
  datacenters = ["sfo"]
  type = "system"

  group "cadvisor" {
    task "cadvisor" {
      driver = "docker"

      config {
        image = "google/cadvisor:v0.27.1"
        volumes = [
          "/:/rootfs:ro",
          "/var/run:/var/run:rw",
          "/sys:/sys:ro",
          "/var/lib/docker/:/var/lib/docker:ro",
          "/dev/disk/:/dev/disk:ro"
        ]
        port_map {
          http = 8080
        }
      }

      service {
        name = "cadvisor"
        port = "http"
        tags = [
          "prometheus.enable=true"
        ]

        check {
          type = "http"
          path = "/"
          interval = "10s"
          timeout = "2s"
        }
      }

      resources {
        cpu    = 500
        memory = 128
        network {
          port "http" {}
        }
      }
    }
  }

  group "node-exporter" {
    count = 1

    task "node-exporter" {
      driver = "exec"

      config {
        command = "node_exporter-0.14.0.linux-amd64/node_exporter"
        args = [
          "--web.listen-address=0.0.0.0:${NOMAD_PORT_http}"
        ]
      }

      artifact {
        source = "https://github.com/prometheus/node_exporter/releases/download/v0.14.0/node_exporter-0.14.0.linux-amd64.tar.gz"
      }

      service {
        name = "node-exporter"
        port = "http"
        tags = ["prometheus.enable=true"]

        check {
          type     = "http"
          path     = "/"
          interval = "10s"
          timeout  = "2s"
        }
      }

      resources {
        network {
          port "http" {}
        }
      }
    }
  }
}