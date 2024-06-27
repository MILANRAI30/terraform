provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}

provider "aws" {
  alias  = "us_east_2"
  region = "us-east-2"
}

variable "regions" {
  default = ["us-east-1", "us-east-2"]
}

locals {
  vpc_cidr_blocks = {
    "us-east-1" = "10.0.0.0/16"
    "us-east-2" = "10.1.0.0/16"
  }

  subnet_cidr_blocks = {
    "us-east-1" = "10.0.1.0/24"
    "us-east-2" = "10.1.1.0/24"
  }

  ami_ids = {
    "us-east-1" = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 AMI ID for us-east-1
    "us-east-2" = "ami-0a91cd140a1fc148a" # Amazon Linux 2 AMI ID for us-east-2
  }
}

module "vpc" {
  source     = "./modules/vpc"
  for_each   = toset(local.regions)
  providers  = { aws = aws.${each.key} }
  cidr_block = local.vpc_cidr_blocks[each.key]
  region     = each.key
}

module "subnet" {
  source       = "./modules/subnet"
  for_each     = toset(local.regions)
  providers    = { aws = aws.${each.key} }
  vpc_id       = module.vpc[each.key].vpc_id
  cidr_block   = local.subnet_cidr_blocks[each.key]
  region       = each.key
}

module "internet_gateway" {
  source     = "./modules/internet_gateway"
  for_each   = toset(local.regions)
  providers  = { aws = aws.${each.key} }
  vpc_id     = module.vpc[each.key].vpc_id
  region     = each.key
}

module "route_table" {
  source         = "./modules/route_table"
  for_each       = toset(local.regions)
  providers      = { aws = aws.${each.key} }
  vpc_id         = module.vpc[each.key].vpc_id
  gateway_id     = module.internet_gateway[each.key].internet_gateway_id
  subnet_id      = module.subnet[each.key].subnet_id
  region         = each.key
}

module "instance" {
  source        = "./modules/instance"
  for_each      = toset(local.regions)
  providers     = { aws = aws.${each.key} }
  ami_id        = local.ami_ids[each.key]
  instance_type = "t2.small"
  subnet_id     = module.subnet[each.key].subnet_id
  region        = each.key
}
