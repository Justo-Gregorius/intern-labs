include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  env      = local.env_vars.locals
}

terraform {
  source = "../../../modules//nlb"
}

dependency "subnets" {
  config_path = "../subnets"
  mock_outputs = {
    subnet_ids = { "public-subnet-a" = "subnet-0000000" }
  }
}

dependency "alb" {
  config_path = "../alb"
  mock_outputs = {
    alb_arn = "arn:aws:elasticloadbalancing:us-east-1:00000000:loadbalancer/app/mock/123"
  }
}

inputs = {
  environment = local.env.environment
  name        = "capstone-prod-nlb"
  vpc_id      = "vpc-0cf94bd10f9fc9222"

  subnet_mappings = {
    "public-a" = {
      subnet_id     = dependency.subnets.outputs.subnet_ids["public-subnet-a"]
      allocation_id = "eipalloc-0221987366f4278a9"
    }
  }

  target_groups = {
    alb = {
      port        = 80
      protocol    = "TCP"
      target_type = "alb"
    }
  }

  target_group_attachments = {
    alb = {
      target_group_key = "alb"
      target_id        = dependency.alb.outputs.alb_arn
    }
  }

  listeners = {
    tcp = {
      port             = 80
      protocol         = "TCP"
      target_group_key = "alb"
    }
  }
}
