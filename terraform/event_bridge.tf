resource "aws_cloudwatch_event_rule" "event_rule_create_table_datacatalog" {
  name        = "invoke-lambda-on-glue-crawler-createTable"
  description = "captura los patrones de eventos de creación de nuevas tablas en el datacatalog"

  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["glue.amazonaws.com"],
      "eventName" : ["CreateTable"]
      "requestParameters" : {
        "databaseName" : ["${aws_glue_catalog_database.glue_catalog_database.name}"],
        "tableInput" : {
          "storageDescriptor" : {
            "parameters" : {
              "typeOfData" : ["table"]
            }
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch_logs_create_table_datacatalog" {
  rule      = aws_cloudwatch_event_rule.event_rule_create_table_datacatalog.name
  target_id = "SendToCloudWatchCreateTable"
  arn       = aws_lambda_function.lambda_function["create_table_pii_mask"].arn
}

resource "aws_cloudwatch_event_rule" "event_rule_create_update_datacatalog" {
  name        = "invoke-lambda-on-glue-crawler-updateTable"
  description = "captura los patrones de eventos de creación de actualización de tablas en el datacatalog"

  event_pattern = jsonencode({
    "source" : ["aws.iam"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventSource" : ["glue.amazonaws.com"],
      "eventName" : ["UpdateTable"]
      "requestParameters" : {
        "databaseName" : ["${aws_glue_catalog_database.glue_catalog_database.name}"],
        "tableInput" : {
          "storageDescriptor" : {
            "parameters" : {
              "typeOfData" : ["table"]
            }
          }
        }
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "cloudwatch_logs_update_table_datacatalog" {
  rule      = aws_cloudwatch_event_rule.event_rule_create_update_datacatalog.name
  target_id = "SendToCloudWatchUpdateTable"
  arn       = aws_lambda_function.lambda_function["create_table_pii_mask"].arn
}