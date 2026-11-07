variable "cluster_name" {
  type = string
}
variable "kubernetes_version" {
  type = string
}
variable "cluster_role_arn" {
  type = string
}
variable "subnet_ids" {
  type = list(string)
}
variable "cluster_security_group_id" {
  type = string
}
variable "enabled_log_types" {
  type = set(string)
}
variable "log_retention_in_days" {
  type = number
}
variable "kms_key_arn" {
  type     = string
  nullable = true
}
variable "tags" {
  type = map(string)
}
