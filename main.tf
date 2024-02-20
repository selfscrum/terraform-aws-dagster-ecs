## dagster - configure dagster for ECS
#


# 
## Keeping it all together in a cluster
#
resource "aws_ecs_cluster" "dagster_cluster" {
  name = "${var.cluster_name}_cluster"
  tags = {
    project = var.qualifier_tag
  }
}


#
## Define the services for the three tasks
#
resource "aws_ecs_service" "dagster_webserver_service" {
  depends_on = [aws_lb.ecs_lb , aws_db_instance.ecs_dagster_db, aws_iam_role_policy.task_execution]
  name            = "${var.cluster_name}_webserver"
  cluster         = aws_ecs_cluster.dagster_cluster.id
  task_definition = aws_ecs_task_definition.webserver.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.cluster_subnet_ids
    security_groups = [aws_security_group.allow_all.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_lb.arn
    container_name   = "${var.cluster_name}_webserver"
    container_port   = 3000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dagster_webserver_service.arn
  }
  lifecycle {
    ignore_changes = [desired_count, task_definition]
    create_before_destroy = true
  }  
  triggers = {
    redeployment = plantimestamp()
  }

  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_ecs_service" "dagster_daemon_service" {
  name            = "${var.cluster_name}_daemon"
  cluster         = aws_ecs_cluster.dagster_cluster.id
  task_definition = aws_ecs_task_definition.daemon.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.cluster_subnet_ids
    security_groups = [aws_security_group.allow_all.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dagster_daemon_service.arn
  }
  lifecycle {
    ignore_changes = [desired_count, task_definition]
    create_before_destroy = true
  }  
  triggers = {
    redeployment = plantimestamp()
  }
  tags = {
    project = var.qualifier_tag
  }
  
  depends_on      = [aws_iam_role_policy.task_execution] 
}

resource "aws_ecs_service" "dagster_usercode_service" {
  name            = "${var.cluster_name}_usercode"
  cluster         = aws_ecs_cluster.dagster_cluster.id
  task_definition = aws_ecs_task_definition.usercode.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = var.cluster_subnet_ids
    security_groups = [aws_security_group.allow_all.id]
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.dagster_usercode_service.arn
  }
  lifecycle {
    ignore_changes = [desired_count, task_definition]
    create_before_destroy = true
  }  
  triggers = {
    redeployment = plantimestamp()
  }
  tags = {
    project = var.qualifier_tag
  }

  depends_on      = [aws_iam_role_policy.task_execution] 
}

#
## Logs for the three services
#
resource "aws_cloudwatch_log_group" "webserver_log" {
  name = "/ecs/${var.cluster_name}-webserver-task-definition"

  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_cloudwatch_log_group" "daemon_log" {
  name = "/ecs/${var.cluster_name}-daemon-task-definition"

  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_cloudwatch_log_group" "usercode_log" {
  name = "/ecs/${var.cluster_name}-usercode-task-definition"

  tags = {
    project = var.qualifier_tag
  }
}

#
##  SG
#
resource "aws_security_group" "allow_all" {
  name        = "${var.cluster_name}_allow_all"
  description = "NBM Dagster Cluster Allow all"
  vpc_id      = var.cluster_vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    project = var.qualifier_tag
  }
}

#
## Load Balancer for the dagster webserver
#
resource "aws_lb" "ecs_lb" {
  name               = "${var.cluster_name}-lb"
  internal           = true
  load_balancer_type = "application"
  security_groups    = [aws_security_group.allow_all.id]
  subnets            = var.cluster_subnet_ids
}

resource "aws_lb_target_group" "ecs_lb" {
  name        = "${var.cluster_name}-lb"
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.cluster_vpc_id
  target_type = "ip"
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_lb_listener" "ecs_lb" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = "3000"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_lb.arn
  }
  lifecycle {
    create_before_destroy = true
  }  
}

#
## VPC Endpoints for ECR
#
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id       = var.cluster_vpc_id
  service_name = "com.amazonaws.${var.region}.ecr.api"
  vpc_endpoint_type = "Interface"

  security_group_ids = [var.db_security_group_id, aws_security_group.allow_all.id]
  subnet_ids         = var.cluster_subnet_ids

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id       = var.cluster_vpc_id 
  service_name = "com.amazonaws.${var.region}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  security_group_ids = [var.db_security_group_id, aws_security_group.allow_all.id]
  subnet_ids         = var.cluster_subnet_ids

  private_dns_enabled = true
}