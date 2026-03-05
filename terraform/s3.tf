# s3.tf defines the s3 bucket where the user will upload images to.
# versioning will preserve duplicate files instead of overwriting the first.


resource "aws_s3_bucket" "uploads" {
  bucket = "${var.project_name}--uploads-${random_id.suffix.hex}"
  force_destroy = true

  tags = {
    Project = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "uploads" {
  bucket = aws_s3_bucket.uploads.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "random_id" "suffix" {
  byte_length = 4
}