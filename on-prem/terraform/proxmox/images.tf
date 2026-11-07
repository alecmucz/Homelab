locals {
  ubuntu_2604_serial = yamldecode(file("${path.module}/../../ansible/roles/cloud_image/defaults/main.yml")).cloud_image_ubuntu_2604_serial
}

data "proxmox_file" "ubuntu_2604_base" {
  node_name    = "pve02"
  datastore_id = "local"
  content_type = "import"
  file_name    = "ubuntu-26.04-base-${local.ubuntu_2604_serial}.qcow2"
}
