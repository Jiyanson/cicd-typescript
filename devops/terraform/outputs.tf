output "instance_id" {
  description = "EC2 instance IDs by K3s node name"
  value = {
    for name, instance in aws_instance.k3s_nodes :
    name => instance.id
  }
}

output "k3s_nodes_public_ips" {
  description = "Public IP addresses by K3s node name"

  value = {
    for name, instance in aws_instance.k3s_nodes :
    name => instance.public_ip
  }
}

output "k3s_nodes_private_ips" {
  description = "Private IP addresses by K3s node name"

  value = {
    for name, instance in aws_instance.k3s_nodes :
    name => instance.private_ip
  }
}

output "ssh_command" {
  description = "SSH commands by K3s node name"
  value = {
    for name, instance in aws_instance.k3s_nodes :
    name => "ssh -i ~/.ssh/id_ed25519 ubuntu@${instance.public_ip}"
  }
}
