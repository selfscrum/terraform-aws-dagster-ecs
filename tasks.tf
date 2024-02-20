resource "aws_ecs_task_definition" "webserver" {
  family                = "tf_${var.cluster_name}_webserver"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = 1024
  memory                = 2048
  task_role_arn         = aws_iam_role.task.arn
  execution_role_arn    = aws_iam_role.execution.arn

  volume {
    name = var.dagster_mounted_volume_name
  }

  container_definitions = <<DEFINITION
  [
    {
      "image": "mikesir87/aws-cli",
      "name": "${var.sidecar_container_name}",
      "command": [
          "/bin/bash -c \"aws s3 cp s3://${var.dagster_config_bucket}/config/ ${var.dagster-container-home} --recursive && aws s3 cp s3://${var.dagster_config_bucket}/pipelines/ ${var.dagster-container-home} --recursive\""
      ],
      "entryPoint": [
          "sh",
          "-c"
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.cluster_name}-daemon-task-definition",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "essential": false,
      "mountPoints": [
        {
          "sourceVolume": "${var.dagster_mounted_volume_name}",
          "containerPath": "${var.dagster-container-home}"
        }
      ]
    },
    {
      "name": "${var.cluster_name}_webserver",
      "image": "${aws_ecr_repository.deploy_ecs_webserver.repository_url}:${var.gitrev}",
      "essential": true,
      "environment": [
          { "name" : "DAGSTER_POSTGRES_DB",       "value" : "${aws_db_instance.ecs_dagster_db.db_name}" },
          { "name" : "DAGSTER_POSTGRES_HOSTNAME", "value" : "${aws_db_instance.ecs_dagster_db.address}" },
          { "name" : "DAGSTER_POSTGRES_PASSWORD", "value" : "${aws_db_instance.ecs_dagster_db.password}" },
          { "name" : "DAGSTER_POSTGRES_USER",     "value" : "${aws_db_instance.ecs_dagster_db.username}" },
          { "name" : "S3_BUCKET_NAME",            "value" : "${aws_s3_bucket.repository_bucket.bucket}" }
      ],
      "command": ["dagster-webserver", "-h", "0.0.0.0", "-p", "3000", "-w", "workspace.yaml" ],
      "logConfiguration": { 
          "logDriver": "awslogs",
          "options": { 
                "awslogs-group" : "/ecs/${var.cluster_name}-webserver-task-definition",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "mountPoints": [
        {
           "sourceVolume":  "${var.dagster_mounted_volume_name}",
           "containerPath": "${var.dagster-container-home}"
        }
      ]
    }
  ]
  DEFINITION
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_ecs_task_definition" "daemon" {
  family                = "tf_${var.cluster_name}_daemon"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = 1024
  memory                = 2048
  task_role_arn         = aws_iam_role.task.arn
  execution_role_arn    = aws_iam_role.execution.arn
  volume {
    name = var.dagster_mounted_volume_name
  }

  container_definitions = <<DEFINITION
  [
    {
      "image": "mikesir87/aws-cli",
      "name": "${var.sidecar_container_name}",
      "command": [
          "/bin/bash -c \"aws s3 cp s3://${var.dagster_config_bucket}/config/ ${var.dagster-container-home} --recursive && aws s3 cp s3://${var.dagster_config_bucket}/pipelines/ ${var.dagster-container-home} --recursive\""
      ],
      "entryPoint": [
          "sh",
          "-c"
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.cluster_name}-daemon-task-definition",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "essential": false,
      "mountPoints": [
        {
          "sourceVolume": "${var.dagster_mounted_volume_name}",
          "containerPath": "${var.dagster-container-home}"
        }
      ]
    },
    {
      "name": "${var.cluster_name}_daemon",
      "image": "${aws_ecr_repository.deploy_ecs_daemon.repository_url}:${var.gitrev}",
      "dependsOn": [
            {
                "containerName": "${var.sidecar_container_name}",
                "condition": "SUCCESS"
            }
      ],
      "essential": true,
      "environment": [
          { "name" : "DAGSTER_POSTGRES_DB",       "value" : "${aws_db_instance.ecs_dagster_db.db_name}" },
          { "name" : "DAGSTER_POSTGRES_HOSTNAME", "value" : "${aws_db_instance.ecs_dagster_db.address}" },
          { "name" : "DAGSTER_POSTGRES_PASSWORD", "value" : "${aws_db_instance.ecs_dagster_db.password}" },
          { "name" : "DAGSTER_POSTGRES_USER",     "value" : "${aws_db_instance.ecs_dagster_db.username}" },
          { "name" : "S3_BUCKET_NAME",            "value" : "${aws_s3_bucket.repository_bucket.bucket}" }
      ],
      "command": ["dagster-daemon", "run"],
      "logConfiguration": { 
          "logDriver": "awslogs",
          "options": { 
                "awslogs-group" : "/ecs/${var.cluster_name}-daemon-task-definition",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
      "mountPoints": [
        {
           "sourceVolume":  "${var.dagster_mounted_volume_name}",
           "containerPath": "${var.dagster-container-home}"
        }
      ]
    }
  ]
  DEFINITION
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_ecs_task_definition" "usercode" {
  family                = "tf_${var.cluster_name}_usercode"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = 1024
  memory                = 2048
  task_role_arn         = aws_iam_role.task.arn
  execution_role_arn    = aws_iam_role.execution.arn
  volume {
    name = var.dagster_mounted_volume_name
  }

  container_definitions = <<DEFINITION
  [
  {
      "image": "mikesir87/aws-cli",
      "name": "${var.sidecar_container_name}",
      "command": [
          "/bin/bash -c \"aws s3 cp s3://${var.dagster_config_bucket}/config/ ${var.dagster-container-home} --recursive && aws s3 cp s3://${var.dagster_config_bucket}/pipelines/ ${var.dagster-container-home} --recursive\""
      ],
      "entryPoint": [
          "sh",
          "-c"
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/${var.cluster_name}-usercode-task-definition",
          "awslogs-region": "${var.region}",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "essential": false,
      "mountPoints": [
        {
          "sourceVolume": "${var.dagster_mounted_volume_name}",
          "containerPath": "${var.dagster-container-home}"
        }
      ]
    },
    {
      "name" : "${var.cluster_name}_usercode",
      "image" : "${aws_ecr_repository.deploy_ecs_usercode.repository_url}:${var.gitrev}",
      "essential" : true,
      "environment": [
          { "name" : "DAGSTER_POSTGRES_DB",       "value" : "${aws_db_instance.ecs_dagster_db.db_name}" },
          { "name" : "DAGSTER_POSTGRES_HOSTNAME", "value" : "${aws_db_instance.ecs_dagster_db.address}" },
          { "name" : "DAGSTER_POSTGRES_PASSWORD", "value" : "${aws_db_instance.ecs_dagster_db.password}" },
          { "name" : "DAGSTER_POSTGRES_USER",     "value" : "${aws_db_instance.ecs_dagster_db.username}" },
          { "name" : "DAGSTER_CURRENT_IMAGE",     "value" : "${aws_ecr_repository.deploy_ecs_usercode.repository_url}" },
          { "name" : "DAGSTER_S3_BUCKET",         "value" : "${aws_s3_bucket.repository_bucket.bucket}" }          
      ],
      "command" : ["dagster", "api", "grpc", "-h", "0.0.0.0", "-p", "4000", "-f", "defs.py"],
      "logConfiguration": { 
          "logDriver": "awslogs",
          "options": { 
                "awslogs-group" : "/ecs/${var.cluster_name}-usercode-task-definition",
                "awslogs-region": "${var.region}",
                "awslogs-stream-prefix": "ecs"
            }
        },
      "mountPoints": [
        {
           "sourceVolume":  "${var.dagster_mounted_volume_name}",
           "containerPath": "${var.dagster-container-home}"
        }
      ],
      "portMappings": [
        {
          "containerPort": 4000,
          "hostPort": 4000,
          "protocol": "tcp",
          "appProtocol": "grpc",
          "name": "pm_${var.cluster_name}_usercode"
        }
      ]
    }
  ]
  DEFINITION
  tags = {
    project = var.qualifier_tag
  }
}
