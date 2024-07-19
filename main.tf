// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: MIT-0

locals {
  newbits = ceil(log(var.azs, 2))
  azs     = slice(data.aws_availability_zones.available.names, 0, var.azs)
  subnets = [for i, v in local.azs : cidrsubnet(var.vpc_cidr, local.newbits, i)]
}

#tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
#tfsec:ignore:aws-ec2-no-public-ip-subnet
module "m2_vpc" {
  # checkov:skip=CKV_TF_1:commit hashes cannot be used on Terraform registry sources
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.1.1"

  name                    = var.name
  cidr                    = var.vpc_cidr
  public_subnets          = local.subnets
  azs                     = local.azs
  map_public_ip_on_launch = true
}

#tfsec:ignore:aws-ec2-no-public-egress-sgr
resource "aws_security_group" "example" {
  name        = var.name
  vpc_id      = module.m2_vpc.vpc_id
  description = "M2 Security Group"

  tags = {
    Name = var.name
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.m2_vpc.vpc_cidr_block]
    description = "Allow outbound"
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [module.m2_vpc.vpc_cidr_block]
    description = "Allow ingress from VPC"
  }
  ingress {
    from_port   = 8196
    to_port     = 8196
    protocol    = "TCP"
    cidr_blocks = ["${var.my_public_ip}/32"]
    description = "Allow ingress from users IP"
  }
}

#tfsec:ignore:aws-s3-enable-bucket-logging
module "s3_bucket" {
  # checkov:skip=CKV_TF_1:commit hashes cannot be used on Terraform registry sources
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "4.1.1"

  bucket = "${var.name}-${data.aws_region.current.name}-${data.aws_caller_identity.current.account_id}"

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning = {
    enabled = true
  }

  force_destroy = true
}

resource "aws_s3_object" "example" {
  bucket = module.s3_bucket.s3_bucket_id
  key    = "v1/PlanetsDemo-v1.zip"
  source = "PlanetsDemo-v1.zip"
}

# Create the Environment resource to deploy applications
resource "aws_m2_environment" "example" {
  name                = var.name
  description         = var.name
  engine_type         = var.engine_type
  engine_version      = var.engine_version
  instance_type       = var.instance_type
  security_group_ids  = [aws_security_group.example.id]
  subnet_ids          = module.m2_vpc.public_subnets
  publicly_accessible = true

  # Depends on internet gateway as service needs access to AWS Endpoints to start successfully
  depends_on = [module.m2_vpc]
}

# Create an Application
resource "aws_m2_application" "example" {
  name        = var.name
  engine_type = var.engine_type
  definition {
    content = templatefile("application-definition.json", { s3_bucket = module.s3_bucket.s3_bucket_id, port = var.port })
  }

  tags = {
    engine = var.engine_type
  }

  depends_on = [aws_s3_object.example]
}

# Deploy the Application to the Environment
resource "aws_m2_deployment" "example" {
  environment_id      = aws_m2_environment.example.id
  application_id      = aws_m2_application.example.id
  application_version = 1
  start               = true
}