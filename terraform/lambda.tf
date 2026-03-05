

data "archive_file" "lambda_zip" {
    type = "zip"
    source_dir = "${path.module}/../lambda"
    output_path = "${path.module}/../lambda.zip"
}

resource "aws_lambda_function" "processor" {
    filename = data.archive_file.lambda_zip.output_path
    function_name = "${var.project_name}-processor"
    role = aws_iam_role.lambda_exec.arn
    handler = "handler.lambda_handler"
    runtime = "python3.12"
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    timeout = 30
    layers = ["arn:aws:lambda:us-east-1:688933601990:layer:psycopg2-layer-37:1"]

    environment {
      variables = {
        SECRET_NAME = "pipelineiq/db"
        REGION = var.aws_region
      }
    }

    tags = {
        Project = var.project_name
    }

    vpc_config {
      subnet_ids         = aws_subnet.private[*].id
      security_group_ids = [aws_security_group.rds.id]
    }
}





