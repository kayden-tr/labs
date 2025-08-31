terraform {
  required_version = ">= 0.12"
  required_providers {
    esxi = {
      source = "registry.terraform.io/josenk/esxi"
    }
  }
}

provider "vsphere" {
  esxi_hostname      = "192.168.2.100"
  esxi_hostport      = "22"
  esxi_hostssl       = "443"
  esxi_username      = "root"
  esxi_password      = "@d11llnKhOi"
  password           = "@d11llnKhOi"
  user               = "root"
}

resource "esxi_guest" "vmtest" {
  guest_name         = "vmtest-1"
  disk_store         = "MyDiskStoreVmTest-1"

  network_interfaces {
    virtual_network = "VM Network"
  }

}