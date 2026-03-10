import {
  to = aws_subnet.this["public-subnet-a"]
  id = "subnet-031554c80d082ad50"
}

import {
  to = aws_subnet.this["public-subnet-b"]
  id = "subnet-09774a5e6cd4fc675"
}

import {
  to = aws_subnet.this["private-subnet-a"]
  id = "subnet-0ffcaca8215a0dbb9"
}

import {
  to = aws_subnet.this["private-subnet-b"]
  id = "subnet-005c6553c7856be3a"
}

import {
  to = aws_nat_gateway.this
  id = "nat-00e0f3582f9b38ab1"
}

import {
  to = aws_eip.nat
  id = "eipalloc-002fe8d433de03296"
}

import {
  to = aws_route_table.public
  id = "rtb-0e168d54936861198"
}

import {
  to = aws_route_table.private
  id = "rtb-06f3d0cfe6604d6e0"
}
