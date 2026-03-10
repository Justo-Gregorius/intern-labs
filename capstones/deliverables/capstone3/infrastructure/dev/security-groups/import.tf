import {
  to = aws_security_group.this["alb"]
  id = "sg-017d13c99a80bd702"
}

import {
  to = aws_security_group.this["ec2"]
  id = "sg-009e9c8553da9e963"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["alb-ingress-0"]
  id = "sgr-07d7911ce51346fb6"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-0"]
  id = "sgr-0892dbd2f2f4d2f0f"
}

import {
  to = aws_vpc_security_group_ingress_rule.this["ec2-ingress-1"]
  id = "sgr-09cd67df101adcb2b"
}
