variable "image_name" {
    default = "coreos"
}

variable "floatingip_pool" {
    default = "external"
}

variable "flavor" {
    default = "m1.medium"
}

variable "username" {
  description = "Your openstack username"
}

variable "password" {
  description = "Your openstack password"
}

variable "tenant" {
  description = "Your openstack tenant/project"
}

variable "auth_url" {
  description = "Your openstack auth URL"
}

variable "public_key_path" {
  description = "The path of the ssh pub key"
  default = "~/.ssh/id_rsa.pub"
}

variable "whitelist_network" {
  description = "network to allow connectivity from"
  default = "0.0.0.0/0"
}

variable "external_gateway" {
  description = "uuid of external network"
}

variable "network_cidr" {
  description = "CIDR to use for neutron network"
  default = "192.168.199.0/24"
}

variable "enable_lbaas" {
  description = "DO NOT USE THIS! does not auto-destroy GLHF"
  default = 0
}
