resource "proxmox_download_file" "ubuntu_2604" {
  content_type = "import"
  datastore_id = "local"
  node_name    = "pve02"
  url          = "https://cloud-images.ubuntu.com/releases/26.04/release/ubuntu-26.04-server-cloudimg-amd64.img"
  file_name    = "ubuntu-26.04-server-cloudimg-amd64.qcow2"
}
