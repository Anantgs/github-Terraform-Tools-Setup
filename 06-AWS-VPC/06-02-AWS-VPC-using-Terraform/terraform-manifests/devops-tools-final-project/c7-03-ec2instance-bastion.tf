locals {
  instance_subnet_map = flatten([
    for instance_name, instance_label in var.instance_names : [
      for subnet in module.vpc.public_subnets : {
        name       = instance_name
        label      = instance_label
        subnet_id  = subnet
      }
    ]
  ])
}

output "instance_subnet_map" {
  description = "Mapping of instance names to public subnets"
  value       = local.instance_subnet_map
}

module "ec2_public" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  for_each = { for item in local.instance_subnet_map : "${item.name}-${item.subnet_id}" => item }

  name = "${each.value.label}-Instance"

  instance_type               = var.instance_type
  ami                         = data.aws_ami.amzlinux2.id
  key_name                    = "virginia"
  monitoring                  = false
  vpc_security_group_ids      = [module.public_bastion_sg.security_group_id,module.private_sg.security_group_id]
  # iam_instance_profile        = aws_iam_instance_profile.ssm_profile.name
  subnet_id                   = each.value.subnet_id
  user_data                   = file("ssm-agent-install.sh")
  associate_public_ip_address = true

  tags = {
    Terraform   = "true"
    Environment = "dev"
    purpose     = "${each.value.label}"
  }
}

