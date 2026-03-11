
# Zips the lambda/handler.py file into a deployment package AWS can upload.
data "archive_file" "lambda_zip" {
    type = "zip"
    source_dir = "${path.module}/../lambda"
    output_path = "${path.module}/../lambda.zip"
}

# Creates the lambda function in AWS and uses the zip as the code source.
resource "aws_lambda_function" "processor" {
    filename = data.archive_file.lambda_zip.output_path
    function_name = "${var.project_name}-processor"
    role = aws_iam_role.lambda_exec.arn
    handler = "handler.lambda_handler"
    runtime = "python3.12"
    source_code_hash = data.archive_file.lambda_zip.output_base64sha256
    timeout = 30
    layers = ["arn:aws:lambda:us-east-1:688933601990:layer:psycopg2-layer-312:1"]

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

# Gives S3 permission to invoke the Lambda function when a file is uploaded
resource "aws_lambda_permission" "s3_invoke" {
    statement_id  = "AllowS3Invoke"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.processor.function_name
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.uploads.arn
}

# Wires the S3 bucket to trigger Lambda automatically on every new file upload
resource "aws_s3_bucket_notification" "upload_trigger" {
    bucket = aws_s3_bucket.uploads.id

    lambda_function {
        lambda_function_arn = aws_lambda_function.processor.arn
        events              = ["s3:ObjectCreated:*"]
    }

    depends_on = [aws_lambda_permission.s3_invoke]
}



