resource "aws_lambda_function" "hello_lambda" {
  filename      = data.archive_file.lambda.output_path
  handler       = "app.lambda_handler"
  runtime       = "python3.12"
  function_name = "hello-terraform"
  role          = aws_iam_role.iam_for_lambda.arn
  timeout       = 10

  source_code_hash = data.archive_file.lambda.output_base64sha256

  depends_on = [
    aws_cloudwatch_log_group.lambda_log_group
  ]
  logging_config {
    log_format = "JSON"
  }
}

data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = local.lambda_src_path
  output_path = "${local.building_path}/${local.lambda_code_filename}"
}

resource "null_resource" "sam_metadata_aws_lambda_function_hello_terraform" {
  triggers = {
    resource_name        = "aws_lambda_function.hello_lambda"
    resource_type        = "ZIP_LAMBDA_FUNCTION"
    original_source_code = "${local.lambda_src_path}"
    built_output_path    = "${local.building_path}/${local.lambda_code_filename}"
  }
  depends_on = [
    null_resource.build_lambda_function
  ]
}

resource "null_resource" "build_lambda_function" {
  triggers = {
    build_number = "${timestamp()}" # TODO: calculate hash of lambda function. Mo will have a look at this part
  }
  provisioner "local-exec" {
    command = substr(pathexpand("~"), 0, 1) == "/" ? "./py_build.sh \"${local.lambda_src_path}\" \"${local.building_path}\" \"${local.lambda_code_filename}\" Function" : "powershell.exe -File .\\PyBuild.ps1 ${local.lambda_src_path} ${local.building_path} ${local.lambda_code_filename} Function"
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "lambda_logging" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }
}

resource "aws_iam_policy" "lambda_logging" {
  name        = "lambda_logging"
  path        = "/"
  description = "IAM policy for logging from a lambda"
  policy      = data.aws_iam_policy_document.lambda_logging.json
}

data "aws_iam_policy_document" "dynamosb_access" {
  statement {
    effect = "Allow"

    actions = [
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:PutItem",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:UpdateItem",
    ]

    resources = [
      aws_dynamodb_table.example.arn
    ]
  }
}

resource "aws_iam_policy" "dynamodb_access" {
  name        = "dynamodb_access"
  path        = "/"
  description = "IAM policy for accessing dynamodb"
  policy      = data.aws_iam_policy_document.dynamosb_access.json
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "iam_for_lambda"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.lambda_logging.arn
}

resource "aws_iam_role_policy_attachment" "dynamodb_access" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/hello-terraform"
  retention_in_days = 7
}

resource "aws_lambda_permission" "log_permission" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.hello_lambda.function_name
  principal     = "logs.amazonaws.com"

  source_arn = aws_cloudwatch_log_group.lambda_log_group.arn
  
}