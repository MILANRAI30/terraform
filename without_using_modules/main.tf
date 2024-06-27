 # Providers
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}

# Variables
variable "instance_type" {
  description = "The type of EC2 instance"
  default     = "t2.small"
}

variable "vpc_cidr_block_us_east_1" {
  default = "10.0.0.0/16"
}

variable "vpc_cidr_block_us_east_2" {
  default = "10.1.0.0/16"
}

variable "subnet_cidr_blocks" {
  default = {
    "us-east-1" = "10.0.1.0/24"
    "us-east-2" = "10.1.1.0/24"
  }
}

variable "ami_ids" {
  default = {
    "us-east-1" = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI ID for us-east-1
    "us-east-2" = "ami-0a91cd140a1fc148a" # Amazon Linux 2 AMI ID for us-east-2
  }
}

# Resources

# VPC and Subnets
resource "aws_vpc" "vpc_us_east_1" {
  cidr_block = var.vpc_cidr_block_us_east_1
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC in us-east-1"
  }
}

resource "aws_vpc" "vpc_us_east_2" {
  provider   = aws.us_east_2
  cidr_block = var.vpc_cidr_block_us_east_2
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC in us-east-2"
  }
}

resource "aws_subnet" "subnet_us_east_1" {
  vpc_id     = aws_vpc.vpc_us_east_1.id
  cidr_block = var.subnet_cidr_blocks["us-east-1"]
  availability_zone = "us-east-1a"
  tags = {
    Name = "Subnet in us-east-1"
  }
}

resource "aws_subnet" "subnet_us_east_2" {
  provider   = aws.us_east_2
  vpc_id     = aws_vpc.vpc_us_east_2.id
  cidr_block = var.subnet_cidr_blocks["us-east-2"]
  availability_zone = "us-east-2a"
  tags = {
    Name = "Subnet in us-east-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "gw_us_east_1" {
  vpc_id = aws_vpc.vpc_us_east_1.id

  tags = {
    Name = "Internet Gateway in us-east-1"
  }
}

resource "aws_internet_gateway" "gw_us_east_2" {
  provider = aws.us_east_2
  vpc_id   = aws_vpc.vpc_us_east_2.id

  tags = {
    Name = "Internet Gateway in us-east-2"
  }
}

# Route Table
resource "aws_route_table" "route_us_east_1" {
  vpc_id = aws_vpc.vpc_us_east_1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_us_east_1.id
  }

  tags = {
    Name = "Route Table in us-east-1"
  }
}

resource "aws_route_table" "route_us_east_2" {
  provider = aws.us_east_2
  vpc_id   = aws_vpc.vpc_us_east_2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_us_east_2.id
  }

  tags = {
    Name = "Route Table in us-east-2"
  }
}

resource "aws_route_table_association" "subnet_assoc_us_east_1" {
  subnet_id      = aws_subnet.subnet_us_east_1.id
  route_table_id = aws_route_table.route_us_east_1.id
}

resource "aws_route_table_association" "subnet_assoc_us_east_2" {
  provider       = aws.us_east_2
  subnet_id      = aws_subnet.subnet_us_east_2.id
  route_table_id = aws_route_table.route_us_east_2.id
}

# Key Pair
resource "aws_key_pair" "example" {
  key_name   = "example-key"
  public_key = file("~/.ssh/id_rsa.pub")
}

# EC2 Instances
resource "aws_instance" "instance_us_east_1" {
  ami           = var.ami_ids["us-east-1"]
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet_us_east_1.id
  key_name      = aws_key_pair.example.key_name

  tags = {
    Name = "Instance in us-east-1"
  }
}

resource "aws_instance" "instance_us_east_2" {
  provider      = aws.us_east_2
  ami           = var.ami_ids["us-east-2"]
  instance_type = var.instance_type
  subnet_id     = aws_subnet.subnet_us_east_2.id
  key_name      = aws_key_pair.example.key_name

  tags = {
    Name = "Instance in us-east-2"
  }
}

# Load Balancer (Application Load Balancer example)
resource "aws_lb" "example" {
  name               = "example-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.lb.id]
  subnets            = [aws_subnet.subnet_us_east_1.id, aws_subnet.subnet_us_east_2.id]

  tags = {
    Name = "example-lb"
  }
}

# Volumes
resource "aws_ebs_volume" "example_us_east_1" {
  availability_zone = "us-east-1a"
  size              = 1
  tags = {
    Name = "example-volume-us-east-1"
  }
}

resource "aws_ebs_volume" "example_us_east_2" {
  provider          = aws.us_east_2
  availability_zone = "us-east-2a"
  size              = 1
  tags = {
    Name = "example-volume-us-east-2"
  }
}

# Outputs
output "instance_ips" {
  value = {
    us_east_1 = aws_instance.instance_us_east_1.private_ip
    us_east_2 = aws_instance.instance_us_east_2.private_ip
  }
}
