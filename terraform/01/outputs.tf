output "public_ip" {
  description = "The ec2 instance public ip address"
  value       = aws_instance.example.public_ip
  sensitive   = false
}
