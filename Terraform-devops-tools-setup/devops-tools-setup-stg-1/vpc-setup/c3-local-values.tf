# Define Local Values in Terraform
locals {
  owners = var.business_divsion
  environment = var.environment
  name = "${var.business_divsion}-${var.environment}"
  purpose = var.purpose
  # name = "${local.owners}-${local.environment}"
  common_tags = {
    owners = local.owners
    environment = local.environment
    #purpose = local.purpose
  }
  vpc_tags = {
    owners = local.owners
    environment = local.environment
    purpose = local.purpose
  }
} 