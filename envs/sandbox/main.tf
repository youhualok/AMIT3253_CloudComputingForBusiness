terraform {
  required_version = ">= 1.5.0"
}

data "aws_caller_identity" "current" {}

module "vpc" {
  source = "../../modules/vpc"

  name_prefix          = var.name_prefix
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  azs                  = var.azs
}

module "security_groups" {
  source = "../../modules/security-groups"

  name_prefix = var.name_prefix
  vpc_id      = module.vpc.vpc_id
  vpc_cidr    = module.vpc.vpc_cidr
}

module "s3" {
  source      = "../../modules/s3"
  name_prefix = var.name_prefix
  bucket_name = "assignment-s3-uploads-${data.aws_caller_identity.current.account_id}"
}

module "alb" {
  source = "../../modules/alb"

  name_prefix       = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.security_groups.alb_sg_id
}

resource "random_password" "db" {
  length  = 16
  special = false
}

module "rds" {
  source = "../../modules/rds"

  name_prefix        = var.name_prefix
  private_subnet_ids = module.vpc.private_subnet_ids
  rds_sg_id          = module.security_groups.rds_sg_id
  db_name            = "sports_booking"
  db_username        = "admin"
  db_password        = random_password.db.result
}

module "secrets" {
  source = "../../modules/secrets"

  name_prefix = var.name_prefix
  db_host     = module.rds.db_endpoint
  db_port     = module.rds.db_port
  db_name     = "sports_booking"
  db_username = "admin"
  db_password = random_password.db.result
}

module "asg" {
  source = "../../modules/asg"

  name_prefix        = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  ec2_sg_id          = module.security_groups.ec2_sg_id
  target_group_arn   = module.alb.target_group_arn
  secret_arn         = module.secrets.secret_arn
  
  # Uses the exact bucket name string to avoid undeclared module dependency errors
  artifact_bucket    = "assignment-s3-uploads-${data.aws_caller_identity.current.account_id}"

  depends_on = [
    module.rds,
    module.secrets
  ]
}