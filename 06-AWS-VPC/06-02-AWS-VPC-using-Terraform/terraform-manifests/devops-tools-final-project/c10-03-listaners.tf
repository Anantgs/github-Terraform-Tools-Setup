# Listener
resource "aws_lb_listener" "app_listener" {
  for_each          = aws_lb.test
  load_balancer_arn = each.value.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.test[each.key].arn
  }
}

locals {
  # Define a set of allowed purposes based on the variable instance_names
  allowed_purposes = toset(values(var.instance_names))
  
  # Filter instances based on the allowed purposes
  filtered_instances = {
    for instance_key, instance_details in module.ec2_public :
    instance_key => instance_details
    if contains(local.allowed_purposes, lookup(instance_details.tags_all, "purpose", ""))
  }

  # Group instances by their purpose
  instances_by_purpose = {
    for purpose in local.allowed_purposes :
    purpose => [for instance_key, instance_details in local.filtered_instances : instance_details.id if lookup(instance_details.tags_all, "purpose", "") == purpose]
  }

 }

output "instances_by_purpose" {
  description = "IDs of instances whose purpose matches allowed purposes"
  value       = local.instances_by_purpose
}

locals {
  # Flatten the instances by purpose into a list of objects
  flattened_instances = [
    for purpose, instance_ids in local.instances_by_purpose : [
      for instance_id in instance_ids : {
        instance_id = instance_id
        purpose     = purpose
      }
    ]
  ]

  # Create a map for the for_each loop
  for_each_map = { 
    for inst in flatten(local.flattened_instances) : 
    "${inst.purpose}-${inst.instance_id}" => inst 
  }
}

# Outputs for debugging
output "flattened_instances" {
  description = "Flattened list of instances with their purposes"
  value       = local.flattened_instances
}

output "for_each_map" {
  description = "Map used in the for_each loop for target group attachment"
  value       = local.for_each_map
}

resource "aws_lb_target_group_attachment" "app_tg_attachment" {
  for_each = local.for_each_map

  target_group_arn = aws_lb_target_group.test[each.value.purpose].arn
  target_id        = each.value.instance_id
  port             = 80
}

