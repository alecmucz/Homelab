resource "proxmox_virtual_environment_vm" "dev01" {
  name        = "dev01"
  description = "On-prem dev server: Mojo/MAX, compiler builds, projects. Managed by Terraform."
  tags        = ["proxmox", "terraform", "ubuntu"]

  node_name = "pve02"
  vm_id     = 223

  agent {
    enabled = true
    wait_for_ip { disabled = true }
  }
  stop_on_destroy = true
  on_boot         = true

  machine = "q35"
  bios    = "ovmf"

  efi_disk {
    datastore_id = "local-zfs"
    type         = "4m"
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = 24
    type  = "host"
  }

  memory {
    dedicated = 32768
    floating  = 0
  }

  scsi_hardware = "virtio-scsi-single"

  disk {
    datastore_id = "local-zfs"
    import_from  = data.proxmox_file.ubuntu_2604_base.id
    interface    = "scsi0"
    size         = 64
    iothread     = true
    discard      = "on"
    ssd          = true
  }

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi1"
    size         = 250
    iothread     = true
    discard      = "on"
    ssd          = true
    backup       = false
  }

  hostpci {
    device  = "hostpci0"
    mapping = "gpu-3070"
    pcie    = true
    rombar  = true
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:6E:D2:17"
  }

  initialization {
    datastore_id = "local-zfs"

    ip_config {
      ipv4 {
        address = "10.10.10.23/24"
        gateway = "10.10.10.1"
      }
    }

    dns {
      servers = ["10.10.10.1"]
    }

    user_account {
      username = "ansible"
      keys     = [trimspace(file(pathexpand("~/.ssh/id_ed25519.pub")))]
    }
  }
}
