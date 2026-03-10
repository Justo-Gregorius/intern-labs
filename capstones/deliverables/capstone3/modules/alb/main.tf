# modules/alb/main.tf
resource "aws_lb" "this" {
  name               = var.name
  internal           = false
  load_balancer_type = "application"
  security_groups    = var.security_group_ids
  subnets            = var.subnet_ids

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
    path = each.value.health_check_path
  }
}

resource "aws_lb_target_group_attachment" "this" {
  for_each = var.target_group_attachments

  target_group_arn = aws_lb_target_group.this[each.value.target_group_key].arn
  target_id        = each.value.target_id
  port             = each.value.port
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
