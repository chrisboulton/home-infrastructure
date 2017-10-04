job "traefik" {
  region      = "global"
  datacenters = ["sfo"]
  type = "system"

  group "traefik" {
    task "server" {
      driver = "docker"

      config {
        image = "traefik:1.4"
        volumes = [
          "traefik.toml:/etc/traefik/traefik.toml"
        ]
      }

      template {
        data = <<EOH
defaultEntryPoints = ["http"]

[entryPoints]
  [entryPoints.http]
  address = ":80"

[web]
address = ":8080"
readOnly = true
  [web.metrics.prometheus]
  [web.statistics]

[consulCatalog]
endpoint = "consul.service.consul:8500"
exposedByDefault = false
prefix = "traefik"
domain = "sfo.boulton"

        EOH

        destination = "traefik.toml"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      service {
        name = "http"
        port = "http"
      }

      service {
        name = "traefik"
        port = "admin"
        tags = [
          "prometheus.enable=true"
        ]
      }

      resources {
        cpu = 150
        memory = 512
        network {
          port "http" {
            static = 80
          }
          port "admin" {
            static = 8080
          }
        }
      }
    }
  }
}