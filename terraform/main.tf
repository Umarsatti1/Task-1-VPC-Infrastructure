# VPC
resource "aws_vpc" "main" {
  cidr_block       = var.vpc_cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}

# Public Subnets
resource "aws_subnet" "public_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "Public-Subnet-A"
  }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-Subnet-B"
  }
}

# Public Subnets
resource "aws_subnet" "private_subnet_a" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-Subnet-A"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"

  tags = {
    Name = "Private-Subnet-B"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
 vpc_id = aws_vpc.main.id
 
 tags = {
   Name = "umar-igw"
 }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
    domain = "vpc"

    tags = {
        Name = "nat-gateway-eip"
    }

    depends_on = [aws_internet_gateway.igw]
}

# NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnet_a.id

  tags = {
    Name = "NAT-Gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}

# Route Tables
resource "aws_route_table" "public_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.igw.id
 }
 
 tags = {
   Name = "Public-Route-Table"
 }
}

resource "aws_route_table" "private_rt" {
 vpc_id = aws_vpc.main.id

 route {
  cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat_gateway.id
 }
 
 tags = {
   Name = "Private-Route-Table"
 }
}

# Route Table Association
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_subnet_a.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_subnet_b.id
  route_table_id = aws_route_table.private_rt.id
}

# Security Group Configuration

# Public Security Group
resource "aws_security_group" "public_sg" {
  name        = "public-sg"
  description = "Allows ICMP, SSH, and HTTP traffic from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "public-sg"
  }
}

#Private Security Group
resource "aws_security_group" "private_sg" {
  name        = "private-sg"
  description = "Allows ICMP, SSH, and HTTP traffic from private-sg"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.public_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "private-sg"
  }
}

# EC2 Instances
resource "aws_instance" "public_ec2" {
  count         = 1
  ami           = "ami-00f46ccd1cbfb363e"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public_subnet_a.id
  vpc_security_group_ids = [aws_security_group.public_sg.id]
  associate_public_ip_address = true
  key_name = "umarsatti-us-west-2"

  tags = {
    Name = "Public-EC2"
  }
}

resource "aws_instance" "private_ec2" {
  count         = 1
  ami           = "ami-00f46ccd1cbfb363e"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private_subnet_a.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name = "umarsatti-us-west-2"

  tags = {
    Name = "Private-EC2"
  }
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "vpc_logs" {
  name = "umar-vpc-logs"
  retention_in_days = 7
  skip_destroy = false

  tags = {
    Name = "umar-vpc-logs"
  }
}

# VPC Flow Logs
resource "aws_flow_log" "vpc_flow_logs" {
  iam_role_arn    = aws_iam_role.vpc_flow_logs_role.arn
  log_destination = aws_cloudwatch_log_group.vpc_logs.arn
  max_aggregation_interval = 600
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id
}


# IAM Role and Policy
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["vpc-flow-logs.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "vpc_flow_logs_role" {
  name               = "umar-vpc-flowlogs-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "iam_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
    ]

    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "iam_role_policy" {
  name   = "vpc-flow-logs-policy"
  role   = aws_iam_role.vpc_flow_logs_role.id
  policy = data.aws_iam_policy_document.iam_policy.json
}

# Create S3 Bucket for storing VPC Flow Logs
resource "aws_s3_bucket" "s3_bucket" {
  bucket = var.s3_bucket_name
  force_destroy = true

  tags = {
    Name = var.s3_bucket_name
  }
}

# Send VPC Flow Logs to S3
resource "aws_flow_log" "flow_logs_s3" {
  log_destination      = aws_s3_bucket.s3_bucket.arn
  log_destination_type = "s3"
  max_aggregation_interval = 600
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.main.id
}

# VPC Endpoint
resource "aws_vpc_endpoint" "s3_gateway_endpoint" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "umar-vpc-endpoint-s3"
  }
}