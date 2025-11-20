terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.46.1"
    }
  }
}

provider "proxmox" {
  endpoint = "https://10.202.69.69:8006/"
  insecure = true
  # Token via export dans le terminal
}

# --- 1. LE CONTROL PLANE (Le Chef) ---
resource "proxmox_virtual_environment_vm" "talos_cp" {
  name      = "talos-cp-01"
  node_name = "pve"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 20
    file_format  = "raw"
  }

  cdrom {
    enabled = true
    file_id = "local:iso/talos-amd64.iso"
    interface = "ide2"
  }

  network_device {
    bridge   = "vmbr0"
    model    = "e1000"
    firewall = false
  }

  # Configuration IP Statique pour le Control Plane (Important pour le cluster)
  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "10.202.69.100/16" # IP FIXE DU MASTER
        gateway = "10.202.255.254"
      }
    }
  }

  boot_order = ["ide2", "scsi0"]
  operating_system {
    type = "l26"
  }
}

# --- 2. LES WORKER NODES (Les Ouvriers) ---
resource "proxmox_virtual_environment_vm" "talos_worker" {
  count     = 2                 # On en crée 2 d'un coup
  name      = "talos-worker-${count.index + 1}" # talos-worker-1, talos-worker-2
  node_name = "pve"

  cpu {
    cores = 2
    type  = "host"
  }

  memory {
    dedicated = 2048 # Plus de RAM pour vos applications si possible
  }

  disk {
    datastore_id = "local-lvm"
    interface    = "scsi0"
    size         = 30 # Un peu plus de disque pour les pods
    file_format  = "raw"
  }

  cdrom {
    enabled = true
    file_id = "local:iso/talos-amd64.iso"
    interface = "ide2"
  }

  network_device {
    bridge   = "vmbr0"
    model    = "e1000"
    firewall = false
  }

  # Configuration IP : On incrémente l'IP pour chaque worker (.101, .102)
  initialization {
    datastore_id = "local-lvm"
    ip_config {
      ipv4 {
        address = "10.202.69.${101 + count.index}/16"
        gateway = "10.202.255.254"
      }
    }
  }

  boot_order = ["ide2", "scsi0"]
  operating_system {
    type = "l26"
  }
}
