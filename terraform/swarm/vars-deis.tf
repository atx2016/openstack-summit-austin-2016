variable "deisctl_version" {
    default = "1.12.3"
}

variable "deis_domain" {
  default = ""
  description =  "set if you have a custom domain"
}

variable "deis_keyname" {
  default = "deis"
}

variable "deis_cluster_size" {
    default = 3
}
