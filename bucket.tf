resource "aws_s3_bucket" "repository_bucket" {
  bucket = var.dagster_config_bucket
  tags = {
    project = var.qualifier_tag
  }
}

resource "aws_s3_bucket_versioning" "repository_bucket" {
  bucket = aws_s3_bucket.repository_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Upload workspace config file
resource "aws_s3_object" "workspace" {
  bucket = aws_s3_bucket.repository_bucket.id
  key = "config/${var.workspace_file}"
  acl = "private"
  source = "${var.dagster_init_files}/${var.workspace_file}"
  etag = filemd5("${var.dagster_init_files}/${var.workspace_file}")
  tags = {
    project = var.qualifier_tag
  }
}

// Upload dagster config file
resource "aws_s3_object" "dagster" {
  bucket = aws_s3_bucket.repository_bucket.id
  key = "config/${var.dagster_file}"
  acl = "private" # or can be "public-read"
  source = "${var.dagster_init_files}/${var.dagster_file}"
  etag = filemd5("${var.dagster_init_files}/${var.dagster_file}")
  tags = {
    project = var.qualifier_tag
  }
}

// Upload the syncing pipeline
resource "aws_s3_object" "repo" {
  bucket = aws_s3_bucket.repository_bucket.id
  key = "pipelines/syncing_pipeline.py"
  acl = "private" # or can be "public-read"
  source = "${var.dagster_init_files}/syncing_pipeline.py"
  etag = filemd5("${var.dagster_init_files}/syncing_pipeline.py")
  tags = {
    project = var.qualifier_tag
  }
}
