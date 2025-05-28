variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string
}

variable "my_ip" {
  description = "Personal IP address for SSH access"
  type        = string
}

variable "subnet_ids" {
  description = "List of public subnet IDs"
  type        = list(string)
}

variable "ami_id" {
  description = "AMI to use for the EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
}

variable "certificate_arn" {
  description = "The ARN of the ACM certificate"
  type        = string
}
