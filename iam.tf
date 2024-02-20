data "aws_iam_policy_document" "task_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.webserver_log.arn,
      aws_cloudwatch_log_group.daemon_log.arn,
      aws_cloudwatch_log_group.usercode_log.arn
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:s3:::*"
    ]

    actions = ["s3:ListBucket", "s3:ListAllMyBuckets"]
  }


  statement {
    effect = "Allow"

    resources = [
      "*"
    ]
    actions = [
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeRouteTables",
        "ecs:CreateService",
        "ecs:DeleteService",
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListAccountSettings",
        "ecs:ListServices",
        "ecs:ListTagsForResource",
        "ecs:ListTasks",
        "ecs:RegisterTaskDefinition",
        "ecs:RunTask",
        "ecs:StopTask",
        "ecs:TagResource",
        "ecs:UpdateService",
        "iam:PassRole",
        "logs:GetLogEvents",
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:ListSecrets",
        "servicediscovery:CreateService",
        "servicediscovery:DeleteService",
        "servicediscovery:ListServices",
        "servicediscovery:GetNamespace",
        "servicediscovery:ListTagsForResource",
        "servicediscovery:TagResource"
    ]
}

  statement {
    effect = "Allow"

    resources = [
      "*"
    ]
    actions = ["ecs:DescribeTasks", "ecs:DescribeTaskDefinition"]
  }

  statement {
    effect = "Allow"

    resources = [
      "${var.use_secrets_manager}" ? data.aws_secretsmanager_secret_version.dagster_rds[0].arn : "arn:aws:secretsmanager:no-region:000000000000:secret:non-existent-secret" 
    ]

    actions = [
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecrets",
      "secretsmanager:GetSecretValue"
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "arn:aws:rds:*:*:db:*"
    ]

    actions = ["rds:*"]
  }

  statement {
    effect    = "Allow"
    resources = ["arn:aws:s3:::${var.dagster_config_bucket}", "arn:aws:s3:::${var.dagster_config_bucket}/*"]
    actions   = ["s3:ListBucket", "s3:GetObject"]
  }
}

data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",      
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
  }
}

# role for ecs to create the instance
resource "aws_iam_role" "execution" {
  name               = "${var.cluster_name}-dagster-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags = {
    project = var.qualifier_tag
  }
}

# role for the dagster instance itself
resource "aws_iam_role" "task" {
  name               = "${var.cluster_name}-dagster-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "${var.cluster_name}-dagster-task-execution"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

resource "aws_iam_role_policy" "log_agent" {
  name   = "${var.cluster_name}-dagster-log-permissions"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

/*
-------------------------------------------------------------------------
#
## Define role and the permissions for the ECS tasks
#
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.cluster_name}_ecs_execution_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "${var.cluster_name}_ecs_task_policy"
  description = "Policy for ECS task role"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeNetworkInterfaces",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeTasks",
        "ecs:ListAccountSettings",
        "ecs:RegisterTaskDefinition",
        "ecs:RunTask",
        "ecs:TagResource"
      ],
      "Resource": "arn:aws:rds:*:*:db:*"
    },
    {
      "Effect": "Allow",
      "Action": [
         "ecs:DescribeTasks",
         "ecs:StopTask"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": "iam:PassRole",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
            "iam:PassedToService": "ecs-tasks.amazonaws.com"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "rds:*",
      "Resource": "arn:aws:rds:*:*:db:*"
    }
  ]
}
EOF
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}

#
## Define the policies for the ECR repositories
#
data "aws_caller_identity" "current" {}

resource "aws_ecr_repository_policy" "webserver_policy" {
  repository = aws_ecr_repository.deploy_ecs_webserver.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ecs_execution_role.name}"
      },
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"      
        ]
    }
  ]
}
EOF
}

resource "aws_ecr_repository_policy" "daemon_policy" {
  repository = aws_ecr_repository.deploy_ecs_daemon.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ecs_execution_role.name}"
      },
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
EOF
}

resource "aws_ecr_repository_policy" "usercode_policy" {
  repository = aws_ecr_repository.deploy_ecs_usercode.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AllowPull",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.ecs_execution_role.name}"
      },
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    }
  ]
}
EOF
}

*/
