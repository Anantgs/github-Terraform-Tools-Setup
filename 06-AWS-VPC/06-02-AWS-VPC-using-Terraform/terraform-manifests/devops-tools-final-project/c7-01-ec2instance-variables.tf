# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t3.micro"  
}
# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "mandar-verginia"
}

variable "instance_names" {
  type        = map(string)
  description = "Map of instance names"
  default = {
    one   = "Elasticsearch"
    # two   = "kibana"
    # three = "logstash"
    # four  = "filebeat"    
    // five  = "logstash-server"   
    // two   = "Vault"
    // Add more instances as needed
  }
}
