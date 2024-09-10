# Extract instance purposes
locals {
  allowed_purposes = toset(values(var.instance_names))
}

# Data source to fetch instances based on the tags
data "aws_instances" "all" {
  filter {
    name   = "tag:purpose"
    values = local.allowed_purposes
  }
}

# Fetch details of each instance using their IDs
data "aws_instance" "detailed" {
  for_each = toset(data.aws_instances.all.ids)
  instance_id = each.value
}

# Extract instance details into a structured format
locals {
  # Gather instance details and include the purpose and subnet ID
  instance_details = [
    for instance in data.aws_instance.detailed : {
      id        = instance.id
      #tags      = instance.tags
      purpose   = lookup(instance.tags, "purpose", "")
      subnet_id = instance.subnet_id
    }
    if contains(local.allowed_purposes, lookup(instance.tags, "purpose", ""))
  ]

  # Group instances by purpose and combine their subnet IDs
  grouped_instances = {
    for purpose in local.allowed_purposes : 
    purpose => {
      instances = [for inst in local.instance_details : inst if inst.purpose == purpose]
      # subnets   = toset([for inst in local.instance_details : inst.subnet_id if inst.purpose == purpose])
    }
  }

}

# # Outputs to display grouped instances and subnets
# output "instance_details" {
#   description = "Instances grouped by purpose with combined subnets"
#   value       = local.instance_details
# }

# # Outputs to display grouped instances and subnets
# output "allowed_purposes" {
#   description = "Instances grouped by purpose with combined subnets"
#   value       = local.allowed_purposes
# }

# Outputs to display grouped instances and subnets
output "grouped_instances" {
  description = "Instances grouped by purpose with combined subnets"
  value       = local.grouped_instances
}


/* ---------------------------------------------------------------------------------- */

# Define a local value for filtering based on the tag 'purpose=loadbalancer'
locals {
  loadbalancer_purpose = "loadbalancer"
}

# Data source to fetch VPCs with purpose = loadbalancer
data "aws_vpc" "loadbalancer_vpcs" {
  filter {
    name   = "tag:purpose"
    values = ["loadbalancer"]
  }
}

# Data source to fetch security groups with purpose = loadbalancer
data "aws_security_groups" "loadbalancer_sg" {
  filter {
    name   = "tag:purpose"
    values = [local.loadbalancer_purpose]
  }
}

# Data source to fetch subnets with purpose = loadbalancer
data "aws_subnets" "loadbalancer_subnets" {
  filter {
    name   = "tag:purpose"
    values = [local.loadbalancer_purpose]
  }
}

# # Use a separate data source to fetch detailed information about each VPC
# data "aws_vpc" "detailed_vpcs" {
#   for_each = toset(data.aws_vpcs.loadbalancer_vpcs.ids)
#   id       = each.value
# }

# Output the IDs of the VPCs retrieved
output "loadbalancer_vpc_ids" {
  description = "IDs of VPCs with purpose=loadbalancer"
  value       = data.aws_vpc.loadbalancer_vpcs.id
}

# Output the IDs of the security groups retrieved
output "loadbalancer_security_group_ids" {
  description = "IDs of security groups with purpose=loadbalancer"
  value       = data.aws_security_groups.loadbalancer_sg.ids
}

# Output the IDs of the subnets retrieved
output "loadbalancer_subnet_ids" {
  description = "IDs of subnets with purpose=loadbalancer"
  value       = data.aws_subnets.loadbalancer_subnets.ids
}

# # Output the names of the subnets for easier identification
# output "loadbalancer_subnet_names" {
#   description = "Names of subnets with purpose=loadbalancer"
#   value       = [for subnet in data.aws_subnets.loadbalancer_subnets.ids : lookup(subnet.tags, "Name", "")]
# }

# # Output the VPC CIDR blocks by looping through the detailed VPC data source
# output "loadbalancer_vpc_cidr_blocks" {
#   description = "CIDR blocks of VPCs with purpose=loadbalancer"
#   value       = [for vpc in data.aws_vpc.detailed_vpcs : vpc.cidr_block]
# }

/* ---------------------------------------------------------------------------------- */

variable "instance_ports" {
  type = map(number)
  default = {
    "Elasticsearch"  = 80
    "kibana"         = 8081
    # Add other instances and ports as needed
  }
}

resource "aws_lb" "test" {

  for_each                   = { for label in var.instance_names : label => label }  
  name                       = "${each.value}-alb1"
  internal                   = false
  load_balancer_type         = "application"
  # security_groups            = [module.loadbalancer_sg.security_group_id]
  security_groups            = data.aws_security_groups.loadbalancer_sg.ids 
  subnets                    = data.aws_subnets.loadbalancer_subnets.ids
  enable_deletion_protection = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    purpose     = "${each.value}"
  }

}

resource "aws_lb_target_group" "test" {

  for_each                          = { for label in var.instance_names : label => label }
  name                              = "${each.value}-alb1"
  # create_attachment                 = false
  port                              = lookup(var.instance_ports, each.value, 80)
  target_type                       = "instance"
  deregistration_delay              = 10
  load_balancing_cross_zone_enabled = false
  protocol_version                  = "HTTP1"  
  protocol                          = "HTTP"
  # vpc_id                            = module.vpc.vpc_id
  vpc_id                            = data.aws_vpc.loadbalancer_vpcs.id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

}

/* ---------------------------------------------------------------------------------- */

variable "listener_ports" {
  type = map(number)
  default = {
    "elasticsearch"  = 80
    "kibana"         = 8081
    # Add other instances and their listener ports as needed
  }
}

# Listener
resource "aws_lb_listener" "app_listener" {
  for_each          = aws_lb.test
  load_balancer_arn = each.value.arn
  port              = lookup(var.listener_ports, each.key, 80) 
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test[each.key].arn
  }
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  # Loop through the instance details, grouping them by their purpose
  for_each = {
    for inst in local.instance_details : 
    "${inst.purpose}-${inst.id}" => {
      instance_id = inst.id
      purpose     = inst.purpose
    }
  }

  # Attach instances to the corresponding target group
  target_group_arn = aws_lb_target_group.test[each.value.purpose].arn
  target_id        = each.value.instance_id
  port             = lookup(var.instance_ports, each.value.purpose, 80)
}
