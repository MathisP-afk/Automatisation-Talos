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
}
