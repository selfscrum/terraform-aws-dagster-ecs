#
## Database for Dagster
#

## get the secret for access of database
data "aws_secretsmanager_secret" "dagster_rds" {
  count = var.use_secrets_manager ? 1 : 0
  name  = var.dagster_rds_secret
}

data "aws_secretsmanager_secret_version" "dagster_rds" {
  count      = var.use_secrets_manager ? 1 : 0
  secret_id  = var.use_secrets_manager ? data.aws_secretsmanager_secret.dagster_rds[0].id : ""
}

locals {
  user                 = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["user"] : var.db_user
  password             = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["password"] : var.db_password
  engine               = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["engine"] : var.db_engine
  engine_version       = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["engine_version"] : var.db_engine_version
  host                 = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["host"] : var.db_host
  port                 = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["port"] : var.db_port
  dbname               = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["dbname"] : var.db_name
  parameter_group_name = var.use_secrets_manager ? jsondecode(data.aws_secretsmanager_secret_version.dagster_rds[0].secret_string)["parameter_group_name"] : var.db_parameter_group_name
}

resource "aws_db_instance" "ecs_dagster_db" {
  db_name                = "postgres"
  identifier             = "${var.cluster_name}-db"
  allocated_storage      = 20
  storage_type           = "gp3"
  instance_class         = "db.t3.medium"
  vpc_security_group_ids = [var.db_security_group_id, aws_security_group.allow_all.id]
  engine                 = local.engine
  engine_version         = local.engine_version
  username               = local.user
  password               = local.password
  parameter_group_name   = local.parameter_group_name
  skip_final_snapshot    = true
  db_subnet_group_name   = aws_db_subnet_group.ecs_dagster_db_subnet_group.name
}

resource "aws_db_subnet_group" "ecs_dagster_db_subnet_group" {
  name       = "${var.cluster_name}_db_subnet_group"
  subnet_ids = var.cluster_subnet_ids

  tags = {
    project = var.qualifier_tag
  }
}
