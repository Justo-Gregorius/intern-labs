import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/app/capstone-dev-alb/7b8f997e3281df31"
}

import {
  to = aws_lb_target_group.this["ec2"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-dev-ec2-tg/501bc5f4abad4abd"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:listener/app/capstone-dev-alb/7b8f997e3281df31/ac5c066dfc7b5211"
}

import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-dev-ec2-tg/501bc5f4abad4abd/i-0fb7d369ebf2ab629" # ID format: TG_ARN/TARGET_ID
}
