variable "crawler_configuration" {
  type        = string
  description = "JSON configuration for AWS Glue crawlers"
  default     = <<EOF
  {
    "Version": 1.0,
    "CrawlerOutput": {
      "Tables": {
        "AddOrUpdateBehavior": "MergeNewColumns"
      }
    }
  }
  EOF
}

variable "subnet_id" {
  default = "subnet-07f037aab7ca137d6"
}

variable "vpc_id" {
  default = "vpc-0a370b834d1b1f658"
}

variable "lambda_map" {
  description = "lambdas backend"

  type = map(object({
    lambda_name           = string,
    handler               = string,
    runtime               = string,
    environment_variables = optional(map(string))
    })
  )
  default = {
    "create_table_pii_mask" = {
      lambda_name = "create_table_pii_mask"
      handler     = "create_table_pii_mask.handler"
      runtime     = "python3.12"
      environment_variables = {
        "glue_job_name" :"glue-job-mask-data-pii"
      }
    },
    "notification_pii_mask" = {
      lambda_name = "notification_pii_mask"
      handler     = "notification_pii_mask.handler"
      runtime     = "python3.12"
      environment_variables = {
        "emailSource" : "johaoduranse@gmail.com",
        "emailTarget" : "johaoduranse@gmail.com"
      },
    }
  }
}
