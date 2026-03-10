import {
  to = aws_security_group.this["alb"]
  id = "sg-09c91c5dded17c262"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-0adfc66837d2f7e9b"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-0d2f7f0e497c22ab6"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-08ed81487396557b9"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-0ff9e64ae284d95b8"
}
