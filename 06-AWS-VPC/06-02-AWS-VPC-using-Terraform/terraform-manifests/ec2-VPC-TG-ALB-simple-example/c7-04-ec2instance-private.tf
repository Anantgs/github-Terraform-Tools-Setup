module "ec2_private" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "5.6.1"
  name = "private-${var.environment}-vm"

  instance_type          = var.instance_type
  key_name               = var.instance_keypair
  monitoring             = true
  vpc_security_group_ids = [module.private_sg.security_group_id]
  user_data              = file("${path.module}/app1-install.sh")
  subnet_id              = module.vpc.private_subnets[0]
  ami                    = data.aws_ami.amzlinux2.id
  tags                   = local.common_tags
}