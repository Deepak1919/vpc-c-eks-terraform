variable "vpc_id" { type = string }
variable "private_subnets" {
  type = map(object({
    id                = string
    availability_zone = string
    cidr_block        = string
  }))
}
variable "tags" { type = map(string) }
