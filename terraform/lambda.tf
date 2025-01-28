data "archive_file" "lambda_package" {
  for_each    = var.lambda_map
  type        = "zip"
  source_file = "${path.root}/templates/lambda_code/${each.value.lambda_name}.py"
  output_path = "${path.root}/templates/lambda_code/${each.value.lambda_name}-${md5(file("${path.root}/templates/lambda_code/${each.value.lambda_name}.py"))}.zip"
}

resource "aws_lambda_function" "lambda_function" {
  for_each      = var.lambda_map
  function_name = "${each.value.lambda_name}-IAC"
  role          = aws_iam_role.pii_mask_role.arn
  handler       = each.value.handler
  runtime       = each.value.runtime
  filename      = data.archive_file.lambda_package[each.key].output_path

  environment {
    variables = each.value.environment_variables
  }
}