include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//alb"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    public_subnet_ids = ["subnet-00000000", "subnet-11111111"]
  }
}

dependency "security_groups" {
  config_path = "../security-groups"
  mock_outputs = {
    security_group_ids = { alb = "sg-000000000" }
  }
}

dependency "ec2" {
  config_path = "../ec2"
  mock_outputs = {
    instance_ids = { web = "i-000000000" }
  }
}

inputs = {
  environment        = local.env.environment
  name               = "capstone-dev-alb"
  vpc_id             = "vpc-0ddbf980fe31ea317" # Ideally from dependency vpc
  subnet_ids         = dependency.subnets.outputs.public_subnet_ids
  security_group_ids = [dependency.security_groups.outputs.security_group_ids["alb"]]

  target_groups = {
    ec2 = {
      port              = 80
      protocol          = "HTTP"
      target_type       = "instance"
      health_check_path = "/"
    }
  }

  target_group_attachments = {
    web = {
      target_group_key = "ec2"
      target_id        = dependency.ec2.outputs.instance_ids["web"]
      port             = 80
    }
  }

  listeners = {
    http = {
      port             = 80
      protocol         = "HTTP"
      target_group_key = "ec2"
    }
  }
}
