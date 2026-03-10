# modules/nlb/outputs.tf
output "nlb_arn" { value = aws_lb.this.arn }
output "nlb_dns" { value = aws_lb.this.dns_name }
output "eip_ids" {
  value = { for k, eip in aws_eip.this : k => eip.id }
}
output "target_group_arns" {
  value = { for k, tg in aws_lb_target_group.this : k => tg.arn }
}
