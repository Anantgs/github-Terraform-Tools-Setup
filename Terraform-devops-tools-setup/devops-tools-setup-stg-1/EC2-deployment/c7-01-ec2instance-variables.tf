# AWS EC2 Instance Type
variable "instance_type" {
  description = "EC2 Instance Type"
  type = string
  default = "t2.micro"  
}
# AWS EC2 Instance Key Pair
variable "instance_keypair" {
  description = "AWS EC2 Key pair that need to be associated with EC2 Instance"
  type = string
  default = "virginia"
}

variable "instance_names" {
  type        = map(string)
  description = "Map of instance names"
  default = {
    one   = "Elasticsearch"
    two   = "kibana"
    three = "sonarqube"
    four  = "trivy"
    five  = "vault"
    # three = "logstash"vi
    # four  = "filebeat"    
    # five  = "logstash-server"   
    # two   = "Vault"
    # Add more instances as needed
  }
}
