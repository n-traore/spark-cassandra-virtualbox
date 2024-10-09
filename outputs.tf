output "Master_IP" {
  value = virtualbox_vm.master.network_adapter.0.ipv4_address
}

output "Workers_IPS" {
  value = local.ls_workers_ips
}