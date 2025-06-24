variable "my_ip" {
  description = "Personal IP address for SSH access"
  type        = string
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

variable "route53_zone_id" {
  description = "The Route 53 hosted zone ID for the domain"
  type        = string
}

variable "domain_name" {
  description = "The domain name to associate with the load balancer"
  type        = string
}
