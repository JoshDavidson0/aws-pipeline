#!/bin/bash
cd terraform
ECR_URL=$(terraform output -raw ecr_repository_url)
EC2_IP=$(terraform output -raw ec2_public_ip)
cd ..
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin $ECR_URL
docker build -t $ECR_URL:latest .
docker push $ECR_URL:latest
echo "Setup complete. To view results go to: http://$EC2_IP:8000/uploads"