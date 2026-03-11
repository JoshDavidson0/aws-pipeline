# outputs.tf defines the values terraform will print to the terminal after terraform apply completes



output "s3_bucket_name" {
  description = "The name of the uploads bucket, including the random suffix"
  value       = aws_s3_bucket.uploads.bucket
}

output "rds_endpoint" {
  description = "The connection endpoint for the Postgres database"
  value       = aws_db_instance.postgres.endpoint
}

output "rds_db_name" {
  description = "The name of the Postgres database inside the RDS instance"
  value       = aws_db_instance.postgres.db_name
}

output "ec2_public_ip" {
  value = aws_instance.app.public_ip
}

output "ecr_repository_url" {
  description = "The ECR repository URL for pushing and pulling the Docker image"
  value       = aws_ecr_repository.app.repository_url
}