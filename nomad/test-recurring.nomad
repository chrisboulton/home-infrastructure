job "test-recurring" {
  region      = "global"
  datacenters = ["sfo"]
  type        = "batch"

  periodic {
    cron             = "*1 * * * * *"
    prohibit_overlap = true
  }

  group "test" {
    count = 1

    task "echo" {
      driver = "docker"

      constraint {
        attribute = "${attr.kernel.name}"
        value     = "linux"
      }

      config {
        image = "hello-world"
      }

      resources {
        cpu    = 500
        memory = 512
      }
    }
  }
}