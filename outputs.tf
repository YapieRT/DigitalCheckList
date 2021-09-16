output "load-balancer_ip" {

  value = aws_instance.nginx-load-balancer-server.public_ip

}

output "database_private_ip" {

  value = aws_instance.mongodb-server.private_ip

}