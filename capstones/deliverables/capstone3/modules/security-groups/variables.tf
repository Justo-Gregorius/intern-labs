variable "vpc_id" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "security_groups" {
  type = map(object({
    description = string
    ingress_rules = list(object({
      description                  = string
      from_port                    = number
      to_port                      = number
      ip_protocol                  = string
      cidr_ipv4                    = optional(string)
      referenced_security_group_id = optional(string)
    }))
  }))
}
