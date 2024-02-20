##
# secrets manager delivers database coordinates
#
variable "cluster_name" {
    type = string
    description = "Name of the cluster"
}

variable "use_secrets_manager" {
    type = bool
    description = "Use AWS Secrets Manager to deliver database coordinates"
}

variable "dagster_rds_secret" {
    type = string
    description = "Name of the secret in AWS Secrets Manager"
}

variable "db_host" {
    type = string
    description = "db host"
    default = ""
}
variable "db_port" {
    type = string
    description = "db port"
    default = ""
}
variable "db_name" {
    type = string
    description = "db dbname"
    default = ""
}
variable "db_engine" {
    type = string
    description = "db engine"
    default = ""
}
variable "db_engine_version" {
    type = string
    description = "db engine version"
    default = ""
}
variable "db_parameter_group_name"  {
    type = string
    description = "db parameter group name"
    default = ""
}
variable "db_user" {
    type = string
    description = "db user"
    default = ""
}
variable "db_password" {
    type = string
    description = "db password"
    sensitive = true
    default = ""
}

variable "qualifier_tag" {
    type = string
    description = "Qualifier for the installation to allow identification"
}

variable "namespace_name" {
    type = string
    description = "internal name the cluster"
}

variable "cluster_vpc_id" {
    type = string
    description = "VPC ID of the cluster"
}

variable "cluster_subnet_ids" {
    type = list(string)
    description = "Subnet IDs of the cluster"
}

variable db_security_group_id {
    type = string
    description = "Security Group ID of the database"
}

variable "region" {
    type = string
    description = "AWS region"
    default = "eu-central-1"
}

variable "dagster_init_files" {
  type        = string
  default     = "./etc/deploy_container"
  description = "The directory where the dagster init files are located."
}

variable "dagster_config_bucket" {
    type = string
    description = "S3 bucket for dagster config"
}

variable "workspace_file" {
  type        = string
  default     = "workspace.yaml"
  description = "The config file needed to run code locations in dagster."
}

variable "dagster_file" {
  type        = string
  default     = "dagster.yaml"
  description = "The config file needed to run dagster."
}

variable "dagster_mounted_volume_name" {
    type        = string
    default     = "dagster"
    description = "The name of the mounted volume."
}

variable "dagster-container-home" {
  type    = string
  default = "/opt/dagster/dagster_home"
  description = "The home directory in the dagster container."
}

variable "sidecar_container_name" {
  type        = string
  default     = "sidecar"
  description = "The name of the sidecar container."
}

variable "gitrev" {
  type        = string
  default     = "latest"
  description = "The git revision to use for the dagster image."
}