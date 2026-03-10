variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "target_groups" {
  type = map(object({
    port              = number
    protocol          = string
    target_type       = string
    health_check_path = optional(string, "/")
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
    port             = optional(number)
  }))
  default = {}
}

variable "listeners" {
  type = map(object({
    port             = number
    protocol         = string
    target_group_key = string
  }))
}
