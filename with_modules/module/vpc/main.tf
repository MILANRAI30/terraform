variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
  tags = {
    Name = "vpc-${var.region}"
  }
}

output "vpc_id" {
  value = aws_vpc.this.id
}
