resource "aws_vpc_endpoint" "s3" {
  vpc_id            = data.aws_subnet.selected.vpc_id
  vpc_endpoint_type = "Gateway"
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  route_table_ids   = [data.aws_vpc.selected.main_route_table_id]
}

output "vpc_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}