#!/bin/bash
amazon-linux-extras install docker -y
service docker start
usermod -a -G docker ec2-user
amazon-linux-extras install postgresql14 -y
SECRET=$(aws secretsmanager get-secret-value --secret-id pipelineiq/db --region us-east-1 --query SecretString --output text)
DB_PASSWORD=$(echo $SECRET | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['password'])")
DB_USERNAME=$(echo $SECRET | python3 -c "import sys, json; print(json.loads(sys.stdin.read())['username'])")
export PGPASSWORD=$DB_PASSWORD
until psql -h pipelineiq-db.ck9oyg06w26s.us-east-1.rds.amazonaws.com -U $DB_USERNAME -d pipelineiq -c "SELECT 1;" > /dev/null 2>&1; do
    echo "Waiting for RDS to be ready..."
    sleep 10
done
psql -h pipelineiq-db.ck9oyg06w26s.us-east-1.rds.amazonaws.com -U $DB_USERNAME -d pipelineiq -c "CREATE TABLE IF NOT EXISTS uploads (id SERIAL PRIMARY KEY, filename TEXT NOT NULL, s3_key TEXT NOT NULL, uploaded_at TIMESTAMP DEFAULT NOW());"
psql -h pipelineiq-db.ck9oyg06w26s.us-east-1.rds.amazonaws.com -U $DB_USERNAME -d pipelineiq -c "CREATE TABLE IF NOT EXISTS results (id SERIAL PRIMARY KEY, upload_id INTEGER REFERENCES uploads(id), label TEXT NOT NULL, confidence FLOAT NOT NULL, created_at TIMESTAMP DEFAULT NOW());"
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 688933601990.dkr.ecr.us-east-1.amazonaws.com
while true; do
    docker pull 688933601990.dkr.ecr.us-east-1.amazonaws.com/pipelineiq:latest && break
    sleep 10
done
docker run -d -p 8000:8000 --name pipelineiq-api 688933601990.dkr.ecr.us-east-1.amazonaws.com/pipelineiq:latest