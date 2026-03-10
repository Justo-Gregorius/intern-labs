include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//security-groups"
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id = "vpc-000000000"
  }
}

inputs = {
  vpc_id      = dependency.vpc.outputs.vpc_id
  environment = local.env.environment

  security_groups = {
    alb = {
      description = "ALB Security Group"
      ingress_rules = [
        {
          description = "Allow HTTP"
          from_port   = 80
          to_port     = 80
          ip_protocol = "tcp"
          cidr_ipv4   = "0.0.0.0/0"
        }
      ]
    }
    ec2 = {
      description = "EC2 Security Group"
      ingress_rules = [
        {
          description                  = "Allow HTTP from ALB"
          from_port                    = 80
          to_port                      = 80
          ip_protocol                  = "tcp"
          referenced_security_group_id = "sg-09c91c5dded17c262"
        },
        {
          description = "Allow SSH"
          from_port   = 22
          to_port     = 22
          ip_protocol = "tcp"
          cidr_ipv4   = "10.0.0.0/8"
        }
      ]
    }
  }
}
