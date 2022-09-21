terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.8"
    }
  }
}

locals {
  region                 = "us"
  aws_region             = "ap-south-1"
  #name_prefix            = "${local.aws_region}"
  name_prefix            = "primary"

  # VPC
  num_availability_zones = 3
  vpc_cidr_block         = "172.16.0.0/16"

  # VPN
  #client_vpn_cidr     = "10.64.0.0/22"
  #vpn_server_cert_arn = "arn:aws:acm:us-east-2:787292588001:certificate/23413dbc-7009-4508-9cd3-5a994c76431a"
  #vpn_client_cert_arn = "arn:aws:acm:us-east-2:787292588001:certificate/fb809c9c-9925-4d9c-b381-9ee7257c7ef4"
  #vpn_log_retention   = 400
  #vpn_log_group       = "/${local.region}/${local.aws_region}/vpn/"
  #vpn_log_stream      = "vpn-log"
  #banner_text         = "You are accessing the BetaBionics Cloud.  Unauthorized access is strictly prohibited."

  # Beanstalk
  s3_beanstalk_bucket_name = "elasticbeanstalk-us-east-2-787292588001"
}

provider "aws" {
  region = local.aws_region
}

module "vpc" {
  source = "./vpc"

  name_prefix    = local.name_prefix
  az_count       = local.num_availability_zones
  vpc_cidr_block = local.vpc_cidr_block
}

#module "vpn" {
#  source = "./vpn"
#
#  vpc_id              = module.vpc.vpc_id
#  subnet_ids          = module.vpc.private_subnets[*].id
#  security_group_ids  = [module.vpc.vpc_security_group.id]
#
#  aws_region          = local.aws_region
#  vpc_cidr_block      = local.vpc_cidr_block
#  client_vpn_cidr     = local.client_vpn_cidr
#  vpn_server_cert_arn = local.vpn_server_cert_arn
#  vpn_client_cert_arn = local.vpn_client_cert_arn
#  vpn_log_retention   = local.vpn_log_retention
#  vpn_log_group       = local.vpn_log_group
#  vpn_log_stream      = local.vpn_log_stream
#  banner_text         = local.banner_text
#}

#module "vpc_endpoints" {
#  source = "./vpc_endpoints"
#
#  name_prefix        = local.name_prefix
#  vpc_id             = module.vpc.vpc_id
#  aws_region         = local.aws_region
#  route_table_ids    = module.vpc.private_route_tables[*].id
#  subnet_ids         = module.vpc.private_subnets[*].id
#  security_group_ids = [module.vpc.vpc_security_group.id]
#
#  depends_on = [module.vpc]
#}

#module "mbp_test_dev" {
#  source        = "./beanstalk/mbp_test_dev"
#  env           = "dev"
#  vpc_id        = module.vpc.vpc_id
#  subnet_ids    = module.vpc.private_subnets[*].id
#  instance_type = "t2.micro"
#  min_instances = 1
#  max_instances = 1
#
#  # ami-05d8f8b67258c97cc
#  # aws-elasticbeanstalk-amzn-2020.05.13.x86_64-WindowsServer2016-V2-hvm-202005172036
#  ami_id = "ami-05d8f8b67258c97cc"
#}

# Security Group For Environment
#module "security" {
#  source = "./security"
#
#  region      = var.region
#  partition   = var.partition
#  env         = var.env
#
#  vpc_id = module.vpc.vpc_id
#}

# Fargate Cluster
#module "ecs" {
#  source = "./ecs"
#
#  vpc_id      = module.vpc.vpc_id
#  region      = var.region
#  partition   = var.partition
#  env         = var.env
#  aws_region  = var.aws_region
#}
#
#module "log_data_ingest" {
#  source = "./log_data_ingest"
#
#  enabled = false
#
#  region    = var.region
#  partition = var.partition
#  env       = var.env
#
#  aws_region = var.aws_region
#
#  subnet_ids = module.vpc.private_subnets.*.id
#
#  cluster_id = module.ecs.cluster.id
#
#  security_group_ids = [
#    module.security.env_sg.id,
#    module.vpc_endpoints.private_link_sg.id
#  ]
#
#  container_command            = ["python3.8", "main.py"]
#  container_name               = "log_data_ingest_container"
#  container_image              = "dev_e31b4aad8ff4"
#  container_memory             = 16384
#  container_memory_reservation = 16384
#  container_cpu                = 4096
#  container_user               = "bbuser"
#  container_working_directory  = "/service/bbcloud/fibonacci"
#}

#module "bb_api" {
#  source = "./bb_api"
#
#  name_prefix = "default"
#  vpc_id      = module.vpc.vpc_id
#  subnets     = module.vpc.public_subnets
#}
