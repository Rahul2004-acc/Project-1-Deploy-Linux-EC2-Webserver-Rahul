
output "ec2_instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.webserver.id
}

output "ec2_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.webserver.public_ip
}

output "website_url" {
  description = "URL of the hosted website"
  value       = "http://${aws_instance.webserver.public_ip}"
}
