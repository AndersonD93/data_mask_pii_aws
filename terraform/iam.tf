resource "aws_iam_role" "iam_role" {
  name               = "iam_role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_role_policy" "glue_crawler_policy" {
  name = "GlueCrawlerPolicy"
  role = aws_iam_role.iam_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "ec2:*",
          "lambda:*",
          "cloudwatch:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "redshift:GetClusterCredentials",
          "redshift:DescribeClusters",
          "redshift:DescribeTable",
          "redshift:ListSchemas",
          "redshift:*",
          "redshift-data:*"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "${data.aws_secretsmanager_secret.secret_public_api.arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "pii_mask_role" {
  name               = "pii_mask_role"
  assume_role_policy = data.aws_iam_policy_document.glue_assume_role.json
}

resource "aws_iam_role_policy" "pii_mask_policy" {
  name = "PiiMaskPolicy"
  role = aws_iam_role.pii_mask_role.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "glue:*",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "glue:UseMLTransforms",
          "glue:UpdateWorkflow",
          "glue:UpdateUserDefinedFunction",
          "glue:UpdateTrigger",
          "glue:UpdateTable",
          "glue:UpdatePartition",
          "glue:UpdateMLTransform",
          "glue:UpdateJob",
          "glue:UpdateDevEndpoint",
          "glue:UpdateDatabase",
          "glue:UpdateCrawlerSchedule",
          "glue:UpdateCrawler",
          "glue:UpdateConnection",
          "glue:UpdateClassifier",
          "glue:TagResource",
          "glue:StopTrigger",
          "glue:StopCrawlerSchedule",
          "glue:StopCrawler",
          "glue:StartWorkflowRun",
          "glue:StartTrigger",
          "glue:StartMLLabelingSetGenerationTaskRun",
          "glue:StartMLEvaluationTaskRun",
          "glue:StartJobRun",
          "glue:StartImportLabelsTaskRun",
          "glue:StartExportLabelsTaskRun",
          "glue:StartCrawlerSchedule",
          "glue:StartCrawler",
          "glue:SearchTables",
          "glue:ResetJobBookmark",
          "glue:PutWorkflowRunProperties",
          "glue:PutResourcePolicy",
          "glue:PutDataCatalogEncryptionSettings",
          "glue:ListWorkflows",
          "glue:ListTriggers",
          "glue:ListMLTransforms",
          "glue:ListJobs",
          "glue:ListDevEndpoints",
          "glue:ListCrawlers",
          "glue:ImportCatalogToGlue",
          "glue:GetWorkflow*",
          "glue:GetUserDefinedFunction*",
          "glue:GetTrigger*",
          "glue:GetTags",
          "glue:GetTableVersion*",
          "glue:GetTable*",
          "glue:GetSecurityConfiguration*",
          "glue:GetResourcePolicy",
          "glue:GetPlan",
          "glue:GetPartition*",
          "glue:GetMapping",
          "glue:GetMLTransforms",
          "glue:GetMLTransform",
          "glue:GetMLTaskRuns",
          "glue:GetMLTaskRun",
          "glue:GetJob*",
          "glue:GetDevEndpoint*",
          "glue:GetDataflowGraph",
          "glue:GetDatabase",
          "glue:GetDataCatalogEncryptionSettings",
          "glue:GetCrawler*",
          "glue:GetConnection*",
          "glue:GetClassifier*",
          "glue:GetCatalogImportStatus",
          "glue:CreateWorkflow",
          "glue:CreateSecurityConfiguration",
          "glue:CreateScript",
          "glue:CreatePartition",
          "glue:CreateMLTransform",
          "glue:CreateJob",
          "glue:CreateDevEndpoint",
          "glue:CreateDatabase",
          "glue:CreateCrawler",
          "glue:CreateConnection",
          "glue:CreateClassifier",
          "glue:CancelMLTaskRun",
          "glue:BatchStopJobRun",
          "glue:BatchGet*",
          "glue:BatchCreatePartition"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "ses:SendTemplatedEmail",
          "ses:SendRawEmail",
          "ses:SendEmail",
          "ses:SendBulkTemplatedEmail",
          "ses:ListIdentityPolicies",
          "ses:ListIdentities",
          "ses:GetTemplate",
          "ses:GetIdentityPolicies"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "redshift:*",
          "redshift-data:*"
        ]
        Resource = "*"
      },
    ]
  })
}
