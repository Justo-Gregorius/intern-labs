# modules/nlb/main.tf
resource "aws_eip" "this" {
  for_each = var.subnet_mappings
  domain   = "vpc"
  tags     = merge(var.tags, { Name = "${var.name}-eip-${each.key}" })
}

resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "network"

  dynamic "subnet_mapping" {
    for_each = var.subnet_mappings
    content {
      subnet_id = subnet_mapping.value.subnet_id
      # Use allocated EIP from local module resource for for_each keys
      allocation_id = aws_eip.this[subnet_mapping.key].id
    }
  }

  tags = merge(var.tags, { Name = var.name })
}

resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name        = "${var.environment}-${each.key}-tg"
  port        = each.value.port
  protocol    = each.value.protocol
  vpc_id      = var.vpc_id
  target_type = each.value.target_type

  health_check {
    protocol = "HTTP"
    port     = "80"
    path     = "/"
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
}

resource "aws_lb_listener" "this" {
  for_each = var.listeners

  load_balancer_arn = aws_lb.this.arn
  port              = each.value.port
  protocol          = each.value.protocol

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  }
}
