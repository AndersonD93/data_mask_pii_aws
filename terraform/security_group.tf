

resource "aws_security_group" "security_group_glue" {
  name        = "my-security-group"
  description = "Security group with ingress and egress rules"
  vpc_id      = data.aws_vpc.selected.id

  dynamic "ingress" {
    for_each = local.ingress_rules
    content {
      description = ingress.value.type
      from_port   = ingress.value.port_range
      to_port     = ingress.value.port_range
      protocol    = ingress.value.protocol
      cidr_blocks     = try(ingress.value.cidr_blocks, [])
    }
  }

  dynamic "egress" {
    for_each = local.egress_rules
    content {
      description = egress.value.type
      from_port   = egress.value.port_range
      to_port     = egress.value.port_range
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
}

resource "aws_security_group_rule" "allow_all_traffic_to_anywhere" {
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  security_group_id = aws_security_group.security_group_glue.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all traffic to anywhere"
}

output "security_group_id" {
  value = aws_security_group.security_group_glue.id
}
