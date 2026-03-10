import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-0900246b045e1f9b8"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-00bddfb99c41f5662"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-0e593f7eaa2d2016c"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-06704318baaea8db9"
}

import {
  to = aws_nat_gateway.this
  id = "nat-0e225dce442b44cd1"
}

import {
  to = aws_eip.nat
  id = "eipalloc-065bd692da345ac87"
}

import {
  to = aws_route_table.public
  id = "rtb-06876841cb130a61e"
}

import {
  to = aws_route_table.private
  id = "rtb-009ea3548b0267829"
}
