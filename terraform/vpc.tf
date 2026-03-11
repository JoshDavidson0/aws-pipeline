# vpc.tf defines the private network the rds database will be in.

# Define a range of private IP addresses and allow the vpc to resolve AWS service hostnames to IP addresses
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = { 
        Name = "${var.project_name}-vpc" 
    }
  
}

# Ask AWS which availability zones are available in the region.
data "aws_availability_zones" "available" {
    state = "available"
}

# Create 2 private subnets, each in a different availability zone, for high availability.
# Also to select the first two availability zones available reference data source "aws_availability_zones."
resource "aws_subnet" "private" {
    count = 2
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.${count.index + 1}.0/24"
    availability_zone = data.aws_availability_zones.available.names[count.index]
    tags = { Name = "${var.project_name}-private-${count.index}"}
  
}

# Select the id of every subnet in the list.
resource "aws_db_subnet_group" "main" {
    name = "${var.project_name}-subnet-group"
    subnet_ids = aws_subnet.private[*].id
    tags = { 
        Project = var.project_name
    }
}

# Add a security group as a second layer of defense.
# Only traffic incoming from the Postgres port and IP inside the VPC range may enter.
# Outbound traffic can go wherever necessary.
resource "aws_security_group" "rds" {
    name = "${var.project_name}-rds-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { 
        Name = "${var.project_name}-rds-sg"
    }
}

# Allowing Lambda to reach Rekognition and Secrets manager over HTTPS on port 443.
resource "aws_security_group" "vpc_endpoints" {
    name   = "${var.project_name}-endpoints-sg"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "${var.project_name}-endpoints-sg" }
}

# Endpoints for secrets manager, rekognition, and s3 so the resources in the private subnet can reach them without routing the public internet.
resource "aws_vpc_endpoint" "secretsmanager" {
    vpc_id              = aws_vpc.main.id
    service_name        = "com.amazonaws.${var.aws_region}.secretsmanager"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.vpc_endpoints.id]
    private_dns_enabled = true
    tags = { Name = "${var.project_name}-secretsmanager-endpoint" }
}

resource "aws_vpc_endpoint" "rekognition" {
    vpc_id              = aws_vpc.main.id
    service_name        = "com.amazonaws.${var.aws_region}.rekognition"
    vpc_endpoint_type   = "Interface"
    subnet_ids          = aws_subnet.private[*].id
    security_group_ids = [aws_security_group.vpc_endpoints.id]
    private_dns_enabled = true
    tags = { Name = "${var.project_name}-rekognition-endpoint" }
}

resource "aws_vpc_endpoint" "s3" {
    vpc_id            = aws_vpc.main.id
    service_name      = "com.amazonaws.${var.aws_region}.s3"
    vpc_endpoint_type = "Gateway"
    route_table_ids   = [aws_route_table.public.id, aws_route_table.private.id]
    tags = { Name = "${var.project_name}-s3-endpoint" }
}

# Private route tables give Lambda a path to Rekognition.

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private" {
    count          = 2
    subnet_id      = aws_subnet.private[count.index].id
    route_table_id = aws_route_table.private.id
}