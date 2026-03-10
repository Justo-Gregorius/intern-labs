# modules/security-groups/main.tf
resource "aws_security_group" "this" {
  for_each = var.security_groups

  name        = "${var.environment}-${each.key}-sg"
  description = each.value.description
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.environment}-${each.key}-sg" })
}

locals {
  # Flattening ingress rules for for_each
  ingress_rules = flatten([
    for sg_key, sg in var.security_groups : [
      for idx, rule in sg.ingress_rules : merge(rule, {
        sg_key  = sg_key
        rule_id = "${sg_key}-ingress-${idx}"
      })
    ]
  ])
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = { for r in local.ingress_rules : r.rule_id => r }

  security_group_id            = aws_security_group.this[each.value.sg_key].id
  description                  = each.value.description
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_id
}

resource "aws_vpc_security_group_egress_rule" "all" {
  for_each = var.security_groups

  security_group_id = aws_security_group.this[each.key].id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}
