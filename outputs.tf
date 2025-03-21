



output "instance_jumphost_public_ip" {
  description = "Public address IP of Jump Host"
  value       = aws_instance.jump_host.public_ip
}

output "instance_msr_privte_ip" {
  description = "Private IP address of master"
  value       = aws_instance.k8s_master_instance.private_ip
}

output "instance_wrks_private_ip" {
  description = "Private address IP of worker"
  value       = aws_instance.k8s_instance_wrk.*.private_ip
}
