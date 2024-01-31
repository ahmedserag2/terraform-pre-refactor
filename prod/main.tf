terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "network" {
  source = "../modules/network"
  env = var.env

}

module "asg" {
  source = "../modules/auto-scaling"
  env = var.env
  subnet_ids = module.network.subnet_ids
  vpc_id = module.network.vpc_id
  public_sub_ids = module.network.public_subnet_ids
}