import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/app/capstone-prod-alb/299b00532535abe9"
}

import {
  to = aws_lb_target_group.this["ec2"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-prod-ec2-tg/7ecdfd7d45c73f85"
}

import {
  to = aws_lb_listener.this["http"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:listener/app/capstone-prod-alb/299b00532535abe9/e4c29992de973c44"
}

import {
  to = aws_lb_target_group_attachment.this["web"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-prod-ec2-tg/7ecdfd7d45c73f85/i-06772fc880feda285"
}
