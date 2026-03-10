import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/net/capstone-dev-nlb/c5d1c2f90e92dd0f"
}

import {
  to = aws_eip.this["public-a"]
  id = "eipalloc-002fe8d433de03296"
}

import {
  to = aws_lb_target_group.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-dev-alb-tg/137e1d66e6eec000"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:listener/net/capstone-dev-nlb/c5d1c2f90e92dd0f/d7d726401975b663"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-dev-alb-tg/137e1d66e6eec000/arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/app/capstone-dev-alb/7b8f997e3281df31"
}
