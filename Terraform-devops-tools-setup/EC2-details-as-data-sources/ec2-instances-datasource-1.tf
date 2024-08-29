variable "instance_names" {
  type        = map(string)
  description = "Map of instance names"
  default = {
    one = "Elasticsearch"
    two = "kibana"
  }
}

# Extract the list of instance names
locals {
  instance_purposes = [for v in values(var.instance_names) : v]
}

output "instance_purposes" {
  value = local.instance_purposes
}

# Fetch EC2 instances with the 'purpose' tag using the dynamically generated values
data "aws_instances" "filtered" {
  filter {
    name   = "tag:purpose"  # Note: using 'purpose' in lowercase
    values = local.instance_purposes
  }
}

output "filtered_instance_ids" {
  value = data.aws_instances.filtered.ids
}