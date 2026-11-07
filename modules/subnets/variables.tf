variable "vpc_id" { type = string }
variable "private_subnets" {
  type = map(object({
    availability_zone = string
    cidr_block        = string
    ordinal           = number
  }))
}
variable "tags" { type = map(string) }
