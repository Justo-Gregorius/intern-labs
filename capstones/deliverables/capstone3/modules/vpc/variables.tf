variable "vpc_cidr" {
  type = string
}

variable "environment" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
