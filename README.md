# PipelineIQ
Gaining familiarity with IaaC and Cloud tools with assistance from Claude.

An event-driven cloud pipeline that automatically processes uploaded images using AWS Rekognition, stores results in PostgreSQL, and exposes the data through a REST API.

## Stack: 
AWS (Lambda, S3, RDS, EC2, ECR) · Python · FastAPI · PostgreSQL · Docker · Terraform

---
## How It Works
1. A user uploads an image to S3
2. S3 triggers a Lambda function automatically
3. Lambda sends the image to AWS Rekognition for label detection
4. Lambda writes the image metadata and detected labels to PostgreSQL
5. A FastAPI app running on EC2 exposes the results via REST API
---
## Try It Out
**Requirements:** AWS account, AWS CLI, Terraform, Docker Desktop, Git Bash 
> ⚠️ This project provisions AWS resources (RDS and EC2) that consume free tier hours. Always run `terraform destroy` when finished to avoid unexpected charges.

>⚠️ This project is configured for `us-east-1`. Running in a different region will require updating hardcoded region references in `bootstrap.sh`, `ec2.tf`, and `iam.tf`.


**1. Configure AWS credentials** *(one time setup)*
```bash
aws configure
```
Enter your AWS Access Key ID, Secret Access Key, region (`us-east-1`), and output format (`json`) when prompted. You only need to do this once per machine.

**2. Provision infrastructure** *(run from Git Bash)*
```bash
cd terraform
terraform apply

```
The bucket name is printed by `terraform apply` — look for `s3_bucket_name` in the outputs and substitute it into `<bucket-name>` in step 4.
The ec2_ip is printed by `terraform apply` - look for `ec2_public_ip` in the outputs and substitute it into `<ec2-ip>` in step 5.

**3. Build and deploy** *(run from Git Bash)*
```bash
cd ..
./bootstrap.sh
```
This builds the Docker image, pushes it to ECR, and prints the API URL. EC2 automatically installs dependencies, creates the database tables, and pulls the container in the background. Wait ~10 seconds before proceeding.


**4. Upload an image** *(run from Git Bash)*
```bash
aws s3 cp /c/path/to/your/image.jpg s3://<bucket-name>/image.jpg
```
Wait ~10 seconds for Lambda to process the image. Repeat this step with a different filename to process additional images — no need to re-run `terraform apply`.

**5. View results**

Use the following API endpoint in your browser to see all of your bucket submissions:
```
http://<ec2-ip>:8000/uploads
```
Use the following API endpoint to see the metadata rekognition gathered for each image:
```
http://<ec2-ip>:8000/uploads/{id}
```

**6. Shut down**
```bash
terraform destroy
```
---

## Architecture
All AWS resources are provisioned with Terraform:
- **S3** — file upload storage, triggers Lambda on new object
- **Lambda** — serverless function that calls Rekognition and writes results to Postgres
- **RDS PostgreSQL** — stores image metadata and Rekognition labels
- **EC2** — runs the FastAPI Docker container
- **ECR** — private Docker image registry
- **VPC** — private network, RDS is not publicly accessible
- **IAM** — roles and policies controlling which services can access which resources
- **Secrets Manager** — stores database credentials securely
- **Python** — Lambda functions and FastAPI application
- **FastAPI** — REST API framework serving results from Postgres
- **Docker** — containerizes the FastAPI app for consistent deployment
- **Terraform** — provisions and manages all AWS infrastructure as code
- **Git Bash** — required to run bootstrap.sh and AWS CLI commands on Windows
- **CloudWatch** — logging and monitoring for Lambda and EC2
- **Terraform Outputs** — exposes S3 bucket name and EC2 IP after terraform apply for use in bootstrap.sh and the upload command
---
