terraform apply -target=module.vpc --auto-approve
terraform apply -target=module.ec2_public --auto-approve
terraform output filtered_instance_ids 
terraform output allowed_purposes
terraform output all_instance_tags
terraform output filtered_instance_ids




