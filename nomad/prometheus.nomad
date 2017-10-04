job "prometheus" {
  region      = "global"
  datacenters = ["sfo"]
  type        = "service"

  group "prometheus" {
    task "server" {
      driver = "docker"

      config {
        image = "prom/prometheus:v1.7.2"
        volumes = [
          "/docker/prometheus:/prometheus",
          "prometheus.yml:/etc/prometheus/prometheus.yml"
        ]
      }

      template {
        data = <<EOH
global:
  scrape_interval:     10s
  evaluation_interval: 5s

scrape_configs:
  - job_name: dummy
    consul_sd_configs:
      - server: 'consul.service.consul:8500'
    relabel_configs:
      - source_labels: [__meta_consul_tags]
        regex: .*,prometheus.enable=true,.*
        action: keep
      - source_labels: ['__meta_consul_address', '__meta_consul_tags']
        regex:         '(.*);.*,prometheus.exporter_port:(\d+),'
        replacement: $1:$2
        target_label: __address__
      - source_labels: [__meta_consul_service]
        target_label: job
        EOH

        destination = "prometheus.yml"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      service {
        name = "prometheus"
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
        memory = 1024
        network {
          port "http" {
            static = 9090
          }
        }
      }
    }
  }
}