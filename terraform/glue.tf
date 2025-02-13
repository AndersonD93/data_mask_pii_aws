

resource "aws_glue_catalog_database" "glue_catalog_database" {
  name        = "${local.glue_db_catalog}-aws"
  description = "AWS Glue ${local.glue_db_catalog} Database Catalog"
}

resource "aws_glue_connection" "connection_glue_redshift" {
  name = "${local.glue_db_catalog}-redshift"
  connection_properties = {
    JDBC_CONNECTION_URL = "jdbc:redshift://${aws_redshift_cluster.cluster_test_data_api.endpoint}/${aws_redshift_cluster.cluster_test_data_api.database_name}"
    PASSWORD            = jsondecode(data.aws_secretsmanager_secret_version.existing_secret_version.secret_string)["master_password"]
    USERNAME            = jsondecode(data.aws_secretsmanager_secret_version.existing_secret_version.secret_string)["master_username"]
  }
  physical_connection_requirements {
    availability_zone      = data.aws_subnet.selected.availability_zone
    security_group_id_list = [aws_security_group.security_group_glue.id]
    subnet_id              = data.aws_subnet.selected.id
  }
}


resource "aws_glue_crawler" "crawler_redshift" {
  database_name = aws_glue_catalog_database.glue_catalog_database.name
  name          = "${local.glue_db_catalog}-crawler-redshift-schema-${local.esquema}"
  role          = aws_iam_role.iam_role.arn

  jdbc_target {
    connection_name = aws_glue_connection.connection_glue_redshift.name
    path            = "${aws_redshift_cluster.cluster_test_data_api.database_name}/${local.esquema}/%"
  }
  schedule   = "cron(0 11 1 * ? *)"
  depends_on = [ aws_glue_connection.connection_glue_redshift ]
}


resource "aws_glue_job" "glue_job_mask_data_pii" {
  name              = "glue-job-mask-data-pii"
  role_arn          = aws_iam_role.iam_role.arn
  max_retries       = 0
  number_of_workers = 2
  timeout           = 60
  worker_type       = "G.2X"
  glue_version      = "4.0"
  connections       = [aws_glue_connection.connection_glue_redshift.name]

  command {
    script_location = "s3://${aws_s3_bucket.s3_bucket_glue_scripts.bucket}/job_script/glue_job_data_mask_pii.py"
    python_version  = 3
  }

  default_arguments = {
    "--enable-continuous-log-filter"     = "false"
    "--job-bookmark-option"              = "job-bookmark-disable"
    "--job-language"                     = "python"
    "--debugging"                        = "false"
    "--extra-py-files"                   = "s3://${aws_s3_bucket.s3_bucket_glue_scripts.bucket}/job_script/glue_job_data_mask_pii.py"
    "--enable-auto-scaling"              = "true"
    "--redshiftTmpDir"                   = "s3://test-s3-scripts-glue/tmp/Temporary/"
    "--enable-glue-datacatalog"          = "true"
    "--enable-metrics"                   = "true"
    "--enable-continuous-cloudwatch-log" = "true"
    "--enable-spark-ui"                  = "true"
    "--spark-event-logs-path"            = "s3://test-s3-scripts-glue/tmp/Spark_UI_logs/"
    "--role_arn"                         =  aws_iam_role.iam_role.arn
    "--db_user"                          =  jsondecode(data.aws_secretsmanager_secret_version.existing_secret_version.secret_string)["master_username"]
    "--cluster_id"                       =  aws_redshift_cluster.cluster_test_data_api.id
    "--authorized_users_table"           =  "authorized_users"
    "--lambda_function_name"             =  aws_lambda_function.lambda_function["notification_pii_mask"].function_name
    "--conf"                             = "spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem"
    "--TempDir"                          = "s3://test-s3-scripts-glue/tmp/Temporary/" 
  }
}

output "job_name" {
  value = aws_glue_job.glue_job_mask_data_pii.name
}

output "job_arn" {
  value = aws_glue_job.glue_job_mask_data_pii.arn
}