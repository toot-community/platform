module "networking" {
  source = "../../../modules/networking"

  # VPC
  vpc_name = "ams3-vpc-toot-community-01"
  vpc_cidr = "10.110.0.0/20"
}
