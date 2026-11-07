variable "vpc_id" { type = string }
variable "vpc_cidr" { type = string }
variable "region" { type = string }
variable "trusted_cidrs" { type = list(string) }
variable "allowed_ports" { type = set(number) }
variable "additional_security_group_rules" {
  type = list(object({
    target      = string
    protocol    = string
    from_port   = number
    to_port     = number
    cidr_ipv4   = string
    description = string
  }))
}
variable "tags" { type = map(string) }
