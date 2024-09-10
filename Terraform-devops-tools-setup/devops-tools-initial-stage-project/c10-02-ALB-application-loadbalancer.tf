variable "instance_ports" {
  type = map(number)
  default = {
    "Elasticsearch"  = 80
    "kibana"         = 8081
    # Add other instances and ports as needed
  }
}

resource "aws_lb" "test" {

  for_each = { for label in var.instance_names : label => label }  
  name                       = "${each.value}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [module.loadbalancer_sg.security_group_id]
  subnets                    = module.vpc.public_subnets
  enable_deletion_protection = false

  tags = {
    Terraform   = "true"
    Environment = "dev"
    purpose     = "${each.value}"
  }

}

resource "aws_lb_target_group" "test" {

  for_each                          = { for label in var.instance_names : label => label }
  name                              = "${each.value}-alb"
  # create_attachment                 = false
  port                              = lookup(var.instance_ports, each.value, 80)
  target_type                       = "instance"
  deregistration_delay              = 10
  load_balancing_cross_zone_enabled = false
  protocol_version                  = "HTTP1"  
  protocol                          = "HTTP"
  vpc_id                            = module.vpc.vpc_id
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
    matcher             = "200"
  }

}



