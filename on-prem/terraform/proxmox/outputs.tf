output "dev01_ip" {
  value = proxmox_virtual_environment_vm.dev01.initialization[0].ip_config[0].ipv4[0].address
}
