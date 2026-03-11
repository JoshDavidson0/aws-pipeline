# Defines the role Lambda can assume.
resource "aws_iam_role" "lambda_exec" {
    name = "${var.project_name}-lambda-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "lambda.amazonaws.com"}
        }]
    })
}

# Defines the role EC2 can assume
resource "aws_iam_role" "ec2_role" {
    name = "${var.project_name}-ec2-role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
            Action = "sts:AssumeRole"
            Effect = "Allow"
            Principal = { Service = "ec2.amazonaws.com" }
        }]
    })
}

# Enable Lambda to write to CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_basic" {
    role = aws_iam_role.lambda_exec.name
    policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Enable Lambda to call Rekognition and Secrets Manager.
resource "aws_iam_role_policy" "lambda_permissions" {
    name = "${var.project_name}-lambda-policy"
    role = aws_iam_role.lambda_exec.id

    policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
        Effect = "Allow"
        Action = ["rekognition:DetectLabels"]
        Resource = "*"
    },
    {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = "arn:aws:secretsmanager:us-east-1:688933601990:secret:pipelineiq/db-*"
    },
    {
        Effect = "Allow"
        Action = ["s3:GetObject"]
        Resource = "arn:aws:s3:::pipelineiq--uploads-*/*"
    },
    {
    Effect = "Allow"
    Action = ["ec2:CreateNetworkInterface","ec2:DescribeNetworkInterfaces","ec2:DeleteNetworkInterface"]
    Resource = "*"
    }]
    })
}

# Allow EC2 to pull images from ECR
resource "aws_iam_role_policy" "ec2_ecr_policy" {
    name = "${var.project_name}-ec2-ecr-policy"
    role = aws_iam_role.ec2_role.id
    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect = "Allow"
            Action = [
                "ecr:GetAuthorizationToken",
                "ecr:BatchGetImage",
                "ecr:GetDownloadUrlForLayer"
            ]
            Resource = "*"
        },
        {
            Effect = "Allow"
            Action = ["secretsmanager:GetSecretValue"]
            Resource = "arn:aws:secretsmanager:us-east-1:688933601990:secret:pipelineiq/db-*"
        }]
    })
}

# Instance profile wraps the role so EC2 can use it
resource "aws_iam_instance_profile" "ec2_profile" {
    name = "${var.project_name}-ec2-profile"
    role = aws_iam_role.ec2_role.name
}