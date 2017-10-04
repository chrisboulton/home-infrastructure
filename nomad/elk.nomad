job "elk" {
  region      = "global"
  datacenters = ["sfo"]
  type        = "service"

  group "kibana" {
    count = 1

    task "web" {
      driver = "docker"

      config {
        image = "docker.elastic.co/kibana/kibana:6.0.0-rc1"
      }

      service {
        name = "kibana"
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
            static = 5601
          }
        }
      }

      env {
        ELASTICSEARCH_URL = "http://es.service.consul:9200"
      }
    }
  }

  group "logstash" {
    count = 2

    task "logstash" {
      driver = "docker"

      config {
        image = "docker.elastic.co/logstash/logstash:6.0.0-rc1"
        volumes = [
          "pipeline/:/usr/share/logstash/pipeline/"
        ]
      }

      template {
        data = <<EOH
        input {
          tcp {
            port => 5140
            type => syslog
          }
        }

        filter {
          if [type] == "syslog" {
            grok {
              match => { "message" => "<%{POSINT:syslog_pri}>%{SYSLOGTIMESTAMP:syslog_timestamp} %{SYSLOGHOST:syslog_hostname} %{DATA:syslog_program}(?:\[%{POSINT:syslog_pid}\])?: %{GREEDYDATA:syslog_message}" }
              add_field => [ "received_at", "%{@timestamp}" ]
              add_field => [ "received_from", "%{host}" ]
            }
            date {
              match => [ "syslog_timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
            }
          }
        }

        output {
          elasticsearch {
            hosts => ["es.service.consul:9200"]
            index => "logstash-%{type}-%{+YYYY.MM.dd}"
          }
        }

        EOH

        destination = "pipeline/pipeline.conf"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }

      service {
        name = "logstash-syslog"
        port = "syslog"
      }

      resources {
        cpu = 150
        memory = 1024
        network {
          port "syslog" {
            static = 5140
          }
        }
      }

      env {
        XPACK_MONITORING_ELASTICSEARCH_URL = "http://es.service.consul:9200"
      }
    }
  }

  group "node1" {
    count = 1

    constraint {
      attribute = "${node.unique.name}"
      operator = "="
      value = "node1"
    }

    task "elasticsearch" {
      driver = "docker"

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:6.0.0-rc1"
        hostname = "elasticsearch1"
        volumes = [
          "/docker/elasticsearch/data:/usr/share/elasticsearch/data"
        ]
      }

      service {
        name = "es"
        port = "http"
        tags = [
          "traefik.enable=true"
        ]
        check {
          type     = "http"
          path     = "/_cluster/health?wait_for_status=yellow"
          interval = "10s"
          timeout  = "2s"
        }
      }

      service {
        name = "es-transport"
        port = "transport"
      }

      resources {
        cpu = 150
        memory = 1024
        network {
          port "http" {
            static = 9200
          }

          port "transport" {
            static = 9300
          }
        }
      }

      env {
        cluster.name = "es"
        bootstrap.memory_lock = "true"
        discovery.type = "single-node"
        xpack.security.enabled = "false"
        ES_JAVA_OPTS = "-Xms512m -Xmx512m"
      }
    }
  }
}