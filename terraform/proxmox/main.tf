terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.117"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.10.10.10:8006/"
  insecure = true
}

variable "datastore" {
  type = string
}

resource "proxmox_virtual_environment_vm" "test01" {
  name            = "test01"
  node_name       = "pve01"
  vm_id           = 140
  stop_on_destroy = true

  clone {
    vm_id = 9000
    full  = true
  }

  agent {
    enabled = false
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = var.datastore
    interface    = "scsi0"
    size         = 8
  }

  network_device {
    bridge      = "vmbr0"
    mac_address = "BC:24:11:00:01:40"
  }

  initialization {
    datastore_id = var.datastore
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    user_account {
      username = "ansible"
      keys     = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIO9JclzulQzb/zh3Noor5Ndhtsv2Vj17gTxzU6xJ9qs ansible@mgmt01"]
    }
  }
}
