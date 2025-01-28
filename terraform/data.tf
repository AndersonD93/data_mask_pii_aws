data "aws_iam_policy_document" "glue_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type = "Service"
      identifiers = [
        "glue.amazonaws.com",
        "redshift.amazonaws.com",
        "events.amazonaws.com",
        "lambda.amazonaws.com",
      ]
    }
  }
}

data "aws_subnet" "selected" {
  id = var.subnet_id
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_region" "current" {}