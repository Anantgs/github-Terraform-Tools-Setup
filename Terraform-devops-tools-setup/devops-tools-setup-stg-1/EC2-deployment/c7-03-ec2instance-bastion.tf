# locals {
#   instance_subnet_map = flatten([
#     for instance_name, instance_label in var.instance_names : [
#       for subnet in module.vpc.public_subnets : {
#         name       = instance_name
#         label      = instance_label
#         subnet_id  = subnet
#       }
#     ]
#   ])
# }

# output "instance_subnet_map" {
#   description = "Mapping of instance names to public subnets"
#   value       = local.instance_subnet_map
# }


# module "ec2_public" {
#   depends_on = [ module.vpc ]
#   source  = "terraform-aws-modules/ec2-instance/aws"
#   for_each = { for item in local.instance_subnet_map : "${item.name}-${item.subnet_id}" => item }

#   name = "${each.value.label}-Instance"

#   instance_type               = var.instance_type
#   ami                         = data.aws_ami.amzlinux2.id
#   key_name                    = var.instance_keypair
#   monitoring                  = false
#   vpc_security_group_ids      = [module.public_bastion_sg.security_group_id,module.private_sg.security_group_id]
#   # iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
#   subnet_id                   = each.value.subnet_id
#   user_data                   = file("ssm-agent-install.sh")
#   associate_public_ip_address = true

#   tags = {
#     Terraform   = "true"
#     Environment = "dev"
#     purpose     = "${each.value.label}"
#   }
# }

data "aws_subnets" "public_subnets" {
  filter {
    name   = "tag:purpose"
    values = ["loadbalancer"] # Adjust this filter to match your actual subnet tags
  }
}

output "public_subnets" {
  value = data.aws_subnets.public_subnets.ids
}

data "aws_security_groups" "loadbalancer_sgs" {
  filter {
    name   = "tag:purpose"
    values = ["loadbalancer"]
  }
}

output "loadbalancer_sgs" {
  value = data.aws_security_groups.loadbalancer_sgs.ids
}


locals {
  instance_subnet_map = flatten([
    for instance_name, instance_label in var.instance_names : [
      for subnet in data.aws_subnets.public_subnets.ids : {
        name       = instance_name
        label      = instance_label
        subnet_id  = subnet
      }
    ]
  ])
}


module "ec2_public" {
  # depends_on = [module.vpc]
  source   = "terraform-aws-modules/ec2-instance/aws"
  for_each = { for item in local.instance_subnet_map : "${item.name}-${item.subnet_id}" => item }

  name                        = "${each.value.label}-Instance"
  instance_type               = var.instance_type
  ami                         = data.aws_ami.amzlinux2.id
  key_name                    = var.instance_keypair
  monitoring                  = false
  vpc_security_group_ids      = data.aws_security_groups.loadbalancer_sgs.ids
  subnet_id                   = each.value.subnet_id
  user_data                   = file("ssm-agent-install.sh")
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    purpose     = "${each.value.label}"
  }
}

