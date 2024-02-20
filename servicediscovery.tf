#
## Namespace and Discovery for the three services
#
resource "aws_service_discovery_private_dns_namespace" "ecs_dagster" {
  name = var.namespace_name
  description = "Cluster for NBM Dagster"
  vpc = var.cluster_vpc_id
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_service_discovery_service" "dagster_webserver_service" {
  name = "${var.cluster_name}-webserver"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_dagster.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  tags = {
    project = var.qualifier_tag
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

resource "aws_service_discovery_service" "dagster_daemon_service" {
  name = "${var.cluster_name}-daemon"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_dagster.id

    dns_records {
      ttl  = 10
      type = "A"
    }
  }
  tags = {
    project = var.qualifier_tag
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}


resource "aws_service_discovery_service" "dagster_usercode_service" {
  name = "${var.cluster_name}-usercode"
  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.ecs_dagster.id

    dns_records {
      ttl  = 10
      type = "A"
    }
    dns_records {
      ttl  = 10
      type = "AAAA"
    }
  }
  tags = {
    project = var.qualifier_tag
  }
  health_check_custom_config {
    failure_threshold = 1
  }
}
