#Recuperar valor de secretos

data "aws_secretsmanager_secret" "secret_public_api" {
  name = "secret_mask_data_pii"
}

data "aws_secretsmanager_secret_version" "existing_secret_version" {
  secret_id = data.aws_secretsmanager_secret.secret_public_api.id
}

output "secret_arn" {
  value = data.aws_secretsmanager_secret.secret_public_api.arn
}

resource "aws_redshift_cluster" "cluster_test_data_api" {
  cluster_identifier       = "cluster-test-data-api"
  database_name            = "db_data_api"
  master_username          = jsondecode(data.aws_secretsmanager_secret_version.existing_secret_version.secret_string)["master_username"]
  master_password          = jsondecode(data.aws_secretsmanager_secret_version.existing_secret_version.secret_string)["master_password"]
  node_type                = "dc2.large"
  cluster_type             = "single-node"
  publicly_accessible      = true
  skip_final_snapshot      = true
}

output "redshift_endpoint" {
  value = aws_redshift_cluster.cluster_test_data_api.endpoint
}

output "redshift_port" {
  value = aws_redshift_cluster.cluster_test_data_api.port
}

#Ejecutar Script de creación de esquema e inserción de data

resource "null_resource" "setup_sql" {
  provisioner "local-exec" {
    command = <<EOT
      PGPASSWORD=${aws_redshift_cluster.cluster_test_data_api.master_password} psql \
        -h ${chomp(split(":", aws_redshift_cluster.cluster_test_data_api.endpoint)[0])} \
        -p ${aws_redshift_cluster.cluster_test_data_api.port} \
        -U ${aws_redshift_cluster.cluster_test_data_api.master_username} \
        -d ${aws_redshift_cluster.cluster_test_data_api.database_name} \
        -f ./templates/setup.sql
    EOT
  }
  depends_on = [aws_redshift_cluster.cluster_test_data_api]
}

