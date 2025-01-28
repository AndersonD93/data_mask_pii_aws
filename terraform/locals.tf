locals {
  ingress_rules = [
    {
      type        = "HTTP"
      protocol    = "tcp"
      port_range  = 80
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "Redshift"
      protocol    = "tcp"
      port_range  = 5439
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "HTTPS"
      protocol    = "tcp"
      port_range  = 443
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      type        = "MYSQL/Aurora"
      protocol    = "tcp"
      port_range  = 3306
      cidr_blocks = ["167.0.54.213/32"]
    }
  ]

  egress_rules = [
    {
      type        = "All Traffic"
      protocol    = "-1"
      port_range  = 0
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
  glue_db_catalog        = "glue-db-catalog"
  esquema                = "datapiitest"

}
