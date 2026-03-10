import {
  to = aws_lb.this
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/net/capstone-prod-nlb/461346a62d6d76ef"
}

import {
  to = aws_eip.this["public-a"]
  id = "eipalloc-0221987366f4278a9"
}

import {
  to = aws_lb_target_group.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-prod-alb-tg/4762d56104a3b519"
}

import {
  to = aws_lb_listener.this["tcp"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:listener/net/capstone-prod-nlb/461346a62d6d76ef/244941b977b2ebbd"
}

import {
  to = aws_lb_target_group_attachment.this["alb"]
  id = "arn:aws:elasticloadbalancing:us-east-1:381491904060:targetgroup/capstone-prod-alb-tg/4762d56104a3b519/arn:aws:elasticloadbalancing:us-east-1:381491904060:loadbalancer/app/capstone-prod-alb/299b00532535abe9"
}
