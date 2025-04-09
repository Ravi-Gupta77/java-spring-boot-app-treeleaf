locals {
  tags   = var.tags
  env    = var.env
  region = var.region

  vpc = {
    name = "${var.env}-grafana-test"
    cidr = "15.0.0.0/20"
    azs  = slice(data.aws_availability_zones.available.names, 0, 3)
  }    


}