variable "environment" {
  type = string
}

variable "name" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "subnet_mappings" {
  type = map(object({
    subnet_id     = string
    allocation_id = string
  }))
}

variable "target_groups" {
  type = map(object({
    port        = number
    protocol    = string
    target_type = string
  }))
}

variable "target_group_attachments" {
  type = map(object({
    target_group_key = string
    target_id        = string
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
