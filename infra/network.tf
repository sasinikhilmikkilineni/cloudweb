## VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(local.tags, {
    Name = "${var.project}-vpc"
  })
}

## Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(local.tags, {
    Name = "${var.project}-igw"
  })
}

## Public Subnets (for ALB and NAT Gateway)
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-public-subnet-1"
    Type = "Public"
  })
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true

  tags = merge(local.tags, {
    Name = "${var.project}-public-subnet-2"
    Type = "Public"
  })
}

## Private Subnets (for ECS tasks)
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.region}a"

  tags = merge(local.tags, {
    Name = "${var.project}-private-subnet-1"
    Type = "Private"
  })
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.region}b"

  tags = merge(local.tags, {
    Name = "${var.project}-private-subnet-2"
    Type = "Private"
  })
}

## Elastic IP for NAT Gateway 1
resource "aws_eip" "nat_1" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.project}-nat-eip-1"
  })
}

## Elastic IP for NAT Gateway 2
resource "aws_eip" "nat_2" {
  domain = "vpc"

  tags = merge(local.tags, {
    Name = "${var.project}-nat-eip-2"
  })
}

## NAT Gateway 1 (for private subnet 1)
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id

  tags = merge(local.tags, {
    Name = "${var.project}-nat-gateway-1"
  })

  depends_on = [aws_internet_gateway.main]
}

## NAT Gateway 2 (for private subnet 2)
resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id

  tags = merge(local.tags, {
    Name = "${var.project}-nat-gateway-2"
  })

  depends_on = [aws_internet_gateway.main]
}

## Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-public-rt"
  })
}

## Private Route Table 1 (routes through NAT Gateway 1)
resource "aws_route_table" "private_1" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_1.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-private-rt-1"
  })
}

## Private Route Table 2 (routes through NAT Gateway 2)
resource "aws_route_table" "private_2" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_2.id
  }

  tags = merge(local.tags, {
    Name = "${var.project}-private-rt-2"
  })
}

## Associate public subnets with public route table
resource "aws_route_table_association" "public_1" {
  subnet_id      = aws_subnet.public_1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_2" {
  subnet_id      = aws_subnet.public_2.id
  route_table_id = aws_route_table.public.id
}

## Associate private subnets with private route tables
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_1.id
  route_table_id = aws_route_table.private_1.id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_2.id
}

## Security Group for ALB
resource "aws_security_group" "alb" {
  name        = "${var.project}-alb-sg"
  description = "Security group for Application Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-alb-sg"
  })
}

## Security Group for Backend ECS
resource "aws_security_group" "backend" {
  name        = "${var.project}-backend-sg"
  description = "Security group for backend ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Port 8000 from ALB only"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # Restrict egress: HTTPS to Secrets Manager endpoint SG, and HTTPS to internet for external APIs/Atlas
  egress {
    description     = "HTTPS to Secrets Manager VPC endpoint"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.secrets_endpoint.id]
  }

  egress {
    description = "HTTPS outbound for MongoDB Atlas/PayPal"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-backend-sg"
  })
}

## Security Group for Secrets Manager Interface Endpoint
resource "aws_security_group" "secrets_endpoint" {
  name        = "${var.project}-secrets-endpoint-sg"
  description = "Allow backend tasks to reach Secrets Manager via VPC endpoint"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "HTTPS from backend tasks"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.backend.id]
  }

  egress {
    description = "Allow endpoint responses"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-secrets-endpoint-sg"
  })
}

## Interface VPC Endpoint for Secrets Manager
resource "aws_vpc_endpoint" "secretsmanager" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.region}.secretsmanager"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  security_group_ids  = [aws_security_group.secrets_endpoint.id]
  private_dns_enabled = true

  tags = merge(local.tags, {
    Name = "${var.project}-secretsmanager-endpoint"
  })
}

## Security Group for Frontend ECS
resource "aws_security_group" "frontend" {
  name        = "${var.project}-frontend-sg"
  description = "Security group for frontend ECS tasks"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "Port 80 from ALB only"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, {
    Name = "${var.project}-frontend-sg"
  })
}

## Outputs
output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_ids" {
  value = [aws_subnet.private_1.id, aws_subnet.private_2.id]
}

output "alb_security_group_id" {
  value = aws_security_group.alb.id
}

output "backend_security_group_id" {
  value = aws_security_group.backend.id
}

output "frontend_security_group_id" {
  value = aws_security_group.frontend.id
}
