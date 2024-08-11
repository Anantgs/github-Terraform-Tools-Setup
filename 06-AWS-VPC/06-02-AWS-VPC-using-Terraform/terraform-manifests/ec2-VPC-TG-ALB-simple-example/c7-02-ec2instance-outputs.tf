# VPC Output Values

# Instance Name
output "bastion_instance_id" {
  description = "The ID instance"
  value       = module.ec2_public.id
}

# Instance Name
output "bastion_instance_dns" {
  description = "Dns name of instance"
  value       = module.ec2_public.public_dns
}

# Instance Name
output "private_instance_id" {
  description = "The ID private instance"
  value       = module.ec2_private.id
}

# Instance Name
output "private_instance_private_ip" {
  description = "DNS of private instance"
  value       = module.ec2_private.private_ip
}