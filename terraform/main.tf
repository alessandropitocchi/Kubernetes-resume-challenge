//This is the main configuration file for Terraform. Here we define the resources that we want to create in AWS.
//define the provider and the region where we want to create the resources.

provider "aws" {
  region = var.aws_region
}

//define the availability zones where we want to create the resources.
//use the data source aws_availability_zones to get the availability zones for the region we defined in the provider.
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]    
  }
}

//define the name of the cluster with a local variable using the random_string resource.
locals {
  cluster_name = "eks-ap-cluster-${random_string.random_suffix.result}"
}

//define the random_string resource to generate a random suffix for the cluster name.
resource "random_string" "random_suffix" {
  length  = 8
  special = false
  upper   = false
}

//define vpc and subnets for the EKS cluster.
module "vpc" {
    // using module from the Terraform registry
    source = "terraform-aws-modules/vpc/aws"
    version = "5.8.1"

    // define the name of the VPC, CIDR block, and availability zones.
    name = "eks-vpc"
    cidr = "10.0.0.0/16"
    azs = slice(data.aws_availability_zones.available.names, 0, 3)

    // define the public and private subnets.
    public_subnets = ["10.0.4.0/24", "10.0.5.0/25", "10.0.6.0/24"]
    private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

    // enable NAT gateway, DNS hostnames, and single NAT gateway.
    enable_nat_gateway = true
    single_nat_gateway = true
    enable_dns_hostnames = true

    //tags for the VPC.
    // public subnets are used for ELBs.
    // private subnets are used for internal ELBs.
    public_subnet_tags = {
        "kubernetes.io/role/elb" = "1"
    }

    private_subnet_tags = {
        "kubernetes.io/role/internal-elb" = "1"
    }
}

