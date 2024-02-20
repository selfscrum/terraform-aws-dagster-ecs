#
## ECR Resources to take in the container images  
#
resource "aws_ecr_repository" "deploy_ecs_webserver" {
  name                 = "${var.cluster_name}/webserver"
  force_delete         = true
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_ecr_repository" "deploy_ecs_daemon" {
  name                 = "${var.cluster_name}/daemon"
  force_delete         = true
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_ecr_repository" "deploy_ecs_usercode" {
  name                 = "${var.cluster_name}/usercode"
  force_delete         = true
  tags = {
    project = var.qualifier_tag
  }
}
