output "instance_public_ips" {
  value = [for instance in aws_instance.web : instance.public_ip]
}
