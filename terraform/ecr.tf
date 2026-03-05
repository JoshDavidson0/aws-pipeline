# Docker image registry for the FastAPI container.

resource "aws_ecr_repository" "app" {
    name = var.project_name
    image_tag_mutability = "MUTABLE"
    force_delete = true

    image_scanning_configuration {
      scan_on_push = true
    }

    tags = {
        Project = var.project_name
    }
}

# Output the repository URL so we can push images to it. 
output "aws_ecr_repository_url" {
    value = aws_ecr_repository.app.repository_url
}