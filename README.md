# PipelineIQ

Gaining familiarity with IaaC and Cloud tools with assistance from Claude.

An event-driven cloud pipeline that automatically processes uploaded images using AWS Rekognition, stores results in PostgreSQL, and exposes the data through a REST API.

**Stack:** AWS (Lambda, S3, RDS, EC2, ECR) · Python · FastAPI · PostgreSQL · Docker · Terraform · GitHub Actions

---

## How It Works

1. A user uploads an image to S3
2. S3 triggers a Lambda function automatically
3. Lambda sends the image to AWS Rekognition for label detection
4. Lambda writes the image metadata and detected labels to PostgreSQL
5. A FastAPI app running on EC2 exposes the results via REST API

---

## API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/uploads` | Returns all uploaded images |
| GET | `/uploads/{id}` | Returns a specific image with its Rekognition labels |
| GET | `/uploads?tag=dog` | Filters images by label |

---

## Infrastructure

All AWS resources are provisioned with Terraform:

- **S3** — file upload storage
- **Lambda** — serverless image processing
- **RDS PostgreSQL** — stores metadata and AI results
- **EC2** — runs the FastAPI Docker container
- **ECR** — private Docker image registry
- **VPC** — private network, RDS is not publicly accessible
- **Secrets Manager** — stores database credentials

---

## CI/CD

Pushing to `main` automatically builds a new Docker image, pushes it to ECR, and redeploys the container on EC2 via GitHub Actions.
